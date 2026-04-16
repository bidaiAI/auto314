// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import {IUniswapV2LikeFactory} from "./interfaces/IUniswapV2LikeFactory.sol";
import {IUniswapV2LikePair} from "./interfaces/IUniswapV2LikePair.sol";
import {IUniswapV2LikeRouter02} from "./interfaces/IUniswapV2LikeRouter02.sol";

abstract contract LaunchTokenBase is ERC20, ReentrancyGuard {
    using Address for address payable;

    enum LaunchState {
        Created,
        Bonding314,
        Migrating,
        DEXOnly,
        WhitelistCommit
    }

    uint8 public constant MODE_STANDARD_0314 = 1;
    uint8 public constant MODE_WHITELIST_B314 = 2;
    uint8 public constant MODE_TAXED_1314 = 3;
    uint8 public constant MODE_TAXED_2314 = 4;
    uint8 public constant MODE_TAXED_3314 = 5;
    uint8 public constant MODE_TAXED_4314 = 6;
    uint8 public constant MODE_TAXED_5314 = 7;
    uint8 public constant MODE_TAXED_6314 = 8;
    uint8 public constant MODE_TAXED_7314 = 9;
    uint8 public constant MODE_TAXED_8314 = 10;
    uint8 public constant MODE_TAXED_9314 = 11;
    uint8 public constant MODE_WHITELIST_TAX_F314 = 12;

    uint8 public constant WHITELIST_STATUS_NONE = 0;
    uint8 public constant WHITELIST_STATUS_SCHEDULED = 1;
    uint8 public constant WHITELIST_STATUS_ACTIVE = 2;
    uint8 public constant WHITELIST_STATUS_FINALIZED = 3;
    uint8 public constant WHITELIST_STATUS_EXPIRED = 4;

    uint256 public constant TOTAL_SUPPLY = 1_000_000_000 ether;
    uint256 public constant LP_TOKEN_RESERVE = 200_000_000 ether;
    uint256 public constant SALE_TOKEN_RESERVE = TOTAL_SUPPLY - LP_TOKEN_RESERVE;
    uint256 public constant CURVE_VIRTUAL_TOKEN_RESERVE = 107_036_752 ether;

    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant TOTAL_FEE_BPS = 100;
    uint256 public constant PROTOCOL_FEE_BPS = 30;
    uint256 public constant CREATOR_FEE_BPS = 70;
    uint256 public constant GRADUATION_ASSIST_THRESHOLD = 0.005 ether;
    uint256 public constant CREATOR_FEE_SWEEP_MIN_AGE = 180 days;
    uint256 public constant CREATOR_FEE_SWEEP_MIN_INACTIVITY = 30 days;

    address public constant DEAD_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    uint8 public immutable launchModeId;
    address public immutable creator;
    address public immutable factory;
    address public immutable protocolFeeRecipient;
    address public immutable router;
    address public immutable dexFactory;
    address public immutable wrappedNative;
    uint256 public immutable graduationQuoteReserve;
    uint256 public immutable virtualQuoteReserve;
    uint256 public immutable virtualTokenReserve;
    uint256 public immutable createdAt;
    string public metadataURI;

    LaunchState public state;
    address public pair;

    uint256 public saleTokenReserve;
    uint256 public lpTokenReserve;
    uint256 public curveQuoteReserve;
    uint256 public protocolFeeVault;
    uint256 public creatorFeeVault;
    uint256 public graduationAssistReserve;
    uint256 public lastTradeAt;
    uint256 public whitelistAllocationTokenReserve;

    mapping(address => uint256) public lastBuyBlock;
    mapping(address => bool) public hasTransferredOut;

    event StateTransition(LaunchState indexed previousState, LaunchState indexed newState);
    event BuyExecuted(
        address indexed buyer,
        uint256 grossQuoteIn,
        uint256 netQuoteIn,
        uint256 protocolFee,
        uint256 creatorFee,
        uint256 refundAmount,
        uint256 tokenOut,
        uint256 newCurveQuoteReserve,
        uint256 newSaleTokenReserve
    );
    event SellExecuted(
        address indexed seller,
        uint256 tokenIn,
        uint256 grossQuoteOut,
        uint256 netQuoteOut,
        uint256 protocolFee,
        uint256 creatorFee,
        uint256 newCurveQuoteReserve,
        uint256 newSaleTokenReserve
    );
    event Graduated(
        address indexed pair,
        uint256 tokenAmount,
        uint256 quoteAmountContributed,
        uint256 preloadedQuoteAmount,
        uint256 liquidityBurned
    );
    event UnexpectedNativeReconciled(address indexed caller, uint256 amount);
    event ProtocolFeesClaimed(address indexed recipient, uint256 amount);
    event CreatorFeesClaimed(address indexed recipient, uint256 amount);
    event CreatorFeesSwept(address indexed caller, uint256 amount);
    event GraduationAssistFunded(uint256 amount, uint256 reserveAfter);
    event GraduationAssistTriggered(uint256 amountUsed, uint256 reserveAfter);
    event GraduationAssistReclaimed(uint256 amount, uint256 protocolFeeVaultAfter);
    event GraduationPairUnsyncedQuoteRecovered(address indexed recipient, uint256 amountRecovered);

    error InvalidState();
    error ZeroAmount();
    error ZeroAddress();
    error TransferDisabledPreGraduation();
    error SellCooldownActive();
    error SlippageExceeded();
    error GraduationAlreadyTriggered();
    error PairPolluted();
    error NothingToClaim();
    error Unauthorized();
    error InvalidRecipient();
    error WrappedQuoteTransferFailed();
    error InvalidGraduationConfig();
    error CreatorFeeSweepUnavailable();
    error UnauthorizedFactoryCaller();
    error GraduationAssistUnavailable();
    error GraduationWindowFrozen();

    constructor(
        string memory name_,
        string memory symbol_,
        string memory metadataURI_,
        address creator_,
        address factory_,
        address protocolFeeRecipient_,
        address router_,
        uint256 graduationQuoteReserve_,
        uint8 launchModeId_,
        LaunchState initialState_
    ) ERC20(name_, symbol_) {
        if (graduationQuoteReserve_ == 0) revert InvalidGraduationConfig();
        uint256 virtualQuoteReserve_ = Math.mulDiv(
            graduationQuoteReserve_,
            LP_TOKEN_RESERVE + CURVE_VIRTUAL_TOKEN_RESERVE,
            SALE_TOKEN_RESERVE
        );
        if (virtualQuoteReserve_ == 0) revert InvalidGraduationConfig();
        if (creator_ == address(0) || factory_ == address(0) || protocolFeeRecipient_ == address(0) || router_ == address(0)) revert ZeroAddress();

        creator = creator_;
        factory = factory_;
        protocolFeeRecipient = protocolFeeRecipient_;
        router = router_;
        dexFactory = IUniswapV2LikeRouter02(router_).factory();
        wrappedNative = IUniswapV2LikeRouter02(router_).WETH();
        graduationQuoteReserve = graduationQuoteReserve_;
        virtualQuoteReserve = virtualQuoteReserve_;
        virtualTokenReserve = CURVE_VIRTUAL_TOKEN_RESERVE;
        createdAt = block.timestamp;
        lastTradeAt = block.timestamp;
        metadataURI = metadataURI_;
        launchModeId = launchModeId_;

        _mint(address(this), TOTAL_SUPPLY);
        saleTokenReserve = SALE_TOKEN_RESERVE;
        lpTokenReserve = LP_TOKEN_RESERVE;

        pair = _ensurePair();
        state = initialState_;
        emit StateTransition(LaunchState.Created, initialState_);
    }

    function launchMode() external view returns (uint8) {
        return launchModeId;
    }

    function launchSuffix() external view virtual returns (string memory);

    function buy(uint256 minTokenOut) external payable virtual nonReentrant returns (uint256 tokenOut) {
        _beforeBondingAction();
        if (state != LaunchState.Bonding314) revert InvalidState();
        if (graduationAssistReady()) revert GraduationWindowFrozen();
        tokenOut = _buyFrom(msg.sender, payable(msg.sender), minTokenOut);
    }

    function factoryBuyFor(address recipient, uint256 minTokenOut)
        external
        payable
        virtual
        nonReentrant
        returns (uint256 tokenOut)
    {
        if (msg.sender != factory) revert UnauthorizedFactoryCaller();
        _beforeBondingAction();
        if (state != LaunchState.Bonding314) revert InvalidState();
        if (graduationAssistReady()) revert GraduationWindowFrozen();
        tokenOut = _buyFrom(recipient, payable(recipient), minTokenOut);
    }

    function sell(uint256 tokenAmount, uint256 minQuoteOut)
        external
        virtual
        nonReentrant
        returns (uint256 netQuoteOut)
    {
        _beforeBondingAction();
        if (graduationAssistReady()) revert GraduationWindowFrozen();
        netQuoteOut = _sellFrom(msg.sender, payable(msg.sender), tokenAmount, minQuoteOut);
    }

    function claimProtocolFees() external nonReentrant returns (uint256 amount) {
        amount = _claimProtocolFees(payable(protocolFeeRecipient));
    }

    function claimProtocolFeesTo(address payable recipient) external nonReentrant returns (uint256 amount) {
        amount = _claimProtocolFees(recipient);
    }

    function factoryClaimProtocolFeesTo(address payable recipient) external nonReentrant returns (uint256 amount) {
        if (msg.sender != factory) revert UnauthorizedFactoryCaller();
        amount = _claimProtocolFees(recipient);
    }

    function _claimProtocolFees(address payable recipient) internal returns (uint256 amount) {
        if (msg.sender != protocolFeeRecipient && msg.sender != factory) revert Unauthorized();
        if (recipient == address(0)) revert ZeroAddress();
        amount = protocolFeeVault;
        if (amount == 0) revert NothingToClaim();

        protocolFeeVault = 0;
        recipient.sendValue(amount);

        emit ProtocolFeesClaimed(recipient, amount);
    }

    function claimCreatorFees() external nonReentrant returns (uint256 amount) {
        amount = _claimCreatorFees(payable(creator));
    }

    function claimCreatorFeesTo(address payable recipient) external nonReentrant returns (uint256 amount) {
        amount = _claimCreatorFees(recipient);
    }

    function _claimCreatorFees(address payable recipient) internal returns (uint256 amount) {
        if (msg.sender != creator) revert Unauthorized();
        if (state != LaunchState.DEXOnly) revert InvalidState();
        if (recipient == address(0)) revert ZeroAddress();

        amount = creatorFeeVault;
        if (amount == 0) revert NothingToClaim();

        creatorFeeVault = 0;
        recipient.sendValue(amount);

        emit CreatorFeesClaimed(recipient, amount);
    }

    function sweepAbandonedCreatorFees() external nonReentrant returns (uint256 amount) {
        if (!_creatorFeeSweepReady()) revert CreatorFeeSweepUnavailable();

        amount = creatorFeeVault;
        if (amount == 0) revert NothingToClaim();

        creatorFeeVault = 0;
        protocolFeeVault += amount;

        emit CreatorFeesSwept(msg.sender, amount);
    }

    function reconcileUnexpectedNative() external returns (uint256 amount) {
        amount = _unexpectedNativeBalance();
        if (amount == 0) revert NothingToClaim();

        protocolFeeVault += amount;

        emit UnexpectedNativeReconciled(msg.sender, amount);
    }

    function previewBuy(uint256 grossQuoteIn)
        external
        view
        returns (uint256 tokenOut, uint256 feeAmount, uint256 refundAmount)
    {
        if (state != LaunchState.Bonding314) {
            return (0, 0, 0);
        }
        if (graduationAssistReady()) {
            return (0, 0, grossQuoteIn);
        }
        if (grossQuoteIn == 0) {
            return (0, 0, 0);
        }

        (uint256 usedGross, uint256 netQuoteIn, uint256 protocolFee, uint256 creatorFee) = _quoteBuy(grossQuoteIn);
        tokenOut = _buyTokenOut(netQuoteIn);
        feeAmount = protocolFee + creatorFee;
        refundAmount = grossQuoteIn - usedGross;
    }

    function previewSell(uint256 tokenAmount)
        external
        view
        returns (uint256 grossQuoteOut, uint256 netQuoteOut, uint256 totalFee)
    {
        if (state != LaunchState.Bonding314) {
            return (0, 0, 0);
        }
        if (graduationAssistReady()) {
            return (0, 0, 0);
        }
        if (tokenAmount == 0) {
            return (0, 0, 0);
        }

        (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) = _effectiveReserves();
        uint256 invariant = effectiveQuoteReserve * effectiveTokenReserve;
        uint256 newEffectiveTokenReserve = effectiveTokenReserve + tokenAmount;
        uint256 newEffectiveQuoteReserve = Math.ceilDiv(invariant, newEffectiveTokenReserve);

        grossQuoteOut = effectiveQuoteReserve - newEffectiveQuoteReserve;
        (totalFee,,) = _splitFees(grossQuoteOut);
        netQuoteOut = grossQuoteOut - totalFee;
    }

    function priceQuotePerToken() external view returns (uint256) {
        if (state == LaunchState.DEXOnly) {
            (uint256 tokenReserve, uint256 quoteReserve) = _dexReserves();
            if (tokenReserve == 0) {
                return 0;
            }
            return (quoteReserve * 1e18) / tokenReserve;
        }
        (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) = _effectiveReserves();
        return (effectiveQuoteReserve * 1e18) / effectiveTokenReserve;
    }

    function currentPriceQuotePerToken() external view returns (uint256) {
        if (state == LaunchState.DEXOnly) {
            (uint256 tokenReserve, uint256 quoteReserve) = _dexReserves();
            if (tokenReserve == 0) {
                return 0;
            }
            return (quoteReserve * 1e18) / tokenReserve;
        }

        (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) = _effectiveReserves();
        return (effectiveQuoteReserve * 1e18) / effectiveTokenReserve;
    }

    function remainingQuoteCapacity() external view returns (uint256) {
        if (state != LaunchState.Bonding314) {
            return 0;
        }
        return graduationQuoteReserve - curveQuoteReserve;
    }

    function graduationProgressBps() external view returns (uint256) {
        if (state == LaunchState.DEXOnly) {
            return BPS_DENOMINATOR;
        }
        return (curveQuoteReserve * BPS_DENOMINATOR) / graduationQuoteReserve;
    }

    function displayGraduationProgressBps() external view returns (uint256) {
        if (state == LaunchState.DEXOnly) {
            return BPS_DENOMINATOR;
        }
        return (curveQuoteReserve * BPS_DENOMINATOR) / graduationQuoteReserve;
    }

    function sellUnlockBlock(address account) external view returns (uint256) {
        uint256 lastBuy = lastBuyBlock[account];
        if (lastBuy == 0) return 0;
        return lastBuy + 1;
    }

    function canSell(address account) external view returns (bool) {
        if (graduationAssistReady()) return false;
        uint256 lastBuy = lastBuyBlock[account];
        return lastBuy == 0 || block.number > lastBuy;
    }

    function protocolClaimable() external view returns (uint256) {
        return protocolFeeVault;
    }

    function creatorClaimable() external view returns (uint256) {
        if (state != LaunchState.DEXOnly) {
            return 0;
        }
        return creatorFeeVault;
    }

    function dexReserves() external view returns (uint256 tokenReserve, uint256 quoteReserve) {
        return _dexReserves();
    }

    function creatorFeeSweepReady() external view returns (bool) {
        return _creatorFeeSweepReady();
    }

    function recoverUnsyncedPairQuote() external returns (uint256 recoveredAmount) {
        if (state != LaunchState.Bonding314) revert InvalidState();
        if (pair == address(0)) revert PairPolluted();

        IUniswapV2LikePair lpPair = IUniswapV2LikePair(pair);
        if (lpPair.totalSupply() != 0) revert PairPolluted();

        (uint112 reserve0, uint112 reserve1,) = lpPair.getReserves();
        address token0 = lpPair.token0();
        address token1 = lpPair.token1();

        uint256 tokenReserve;
        uint256 wrappedReserve;
        if (token0 == address(this)) {
            tokenReserve = reserve0;
            wrappedReserve = reserve1;
        } else if (token1 == address(this)) {
            tokenReserve = reserve1;
            wrappedReserve = reserve0;
        } else {
            revert PairPolluted();
        }

        if (tokenReserve != 0) revert PairPolluted();
        if (balanceOf(pair) != 0) revert PairPolluted();
        if (wrappedReserve > graduationQuoteReserve) revert PairPolluted();

        uint256 wrappedBalanceAtPair = IERC20Minimal(wrappedNative).balanceOf(pair);
        if (wrappedBalanceAtPair <= wrappedReserve) revert NothingToClaim();

        recoveredAmount = wrappedBalanceAtPair - wrappedReserve;
        lpPair.skim(protocolFeeRecipient);

        if (balanceOf(pair) != 0) revert PairPolluted();
        if (IERC20Minimal(wrappedNative).balanceOf(pair) != wrappedReserve) revert PairPolluted();

        emit GraduationPairUnsyncedQuoteRecovered(protocolFeeRecipient, recoveredAmount);
    }

    function graduationAssistReady() public view returns (bool) {
        if (state != LaunchState.Bonding314) {
            return false;
        }
        uint256 remaining = _remainingQuoteCapacity();
        return
            remaining != 0
                && remaining <= GRADUATION_ASSIST_THRESHOLD
                && graduationAssistReserve >= remaining
                && _graduationPathHealthy();
    }

    function graduationAssistStatus()
        external
        view
        returns (uint256 threshold, uint256 reserve, uint256 remaining, bool ready)
    {
        threshold = GRADUATION_ASSIST_THRESHOLD;
        reserve = graduationAssistReserve;
        remaining = state == LaunchState.Bonding314 ? _remainingQuoteCapacity() : 0;
        ready = graduationAssistReady();
    }

    function pokeGraduation() external nonReentrant returns (bool graduated) {
        graduated = _tryUseGraduationAssist();
        if (!graduated) revert GraduationAssistUnavailable();
    }

    function pairSnapshot()
        external
        view
        returns (
            address pairAddress,
            uint256 pairTotalSupply,
            uint112 reserve0,
            uint112 reserve1,
            uint256 tokenBalance,
            uint256 wrappedNativeBalance
        )
    {
        pairAddress = pair;
        if (pairAddress == address(0)) {
            return (address(0), 0, 0, 0, 0, 0);
        }

        IUniswapV2LikePair lpPair = IUniswapV2LikePair(pairAddress);
        pairTotalSupply = lpPair.totalSupply();
        (reserve0, reserve1,) = lpPair.getReserves();
        tokenBalance = balanceOf(pairAddress);
        wrappedNativeBalance = IERC20Minimal(wrappedNative).balanceOf(pairAddress);
    }

    function accountedNativeBalance() external view returns (uint256) {
        return _accountedNativeBalance();
    }

    function unexpectedNativeBalance() external view returns (uint256) {
        return _unexpectedNativeBalance();
    }

    function whitelistStatus() public view virtual returns (uint8) {
        return WHITELIST_STATUS_NONE;
    }

    function whitelistSnapshot()
        external
        view
        virtual
        returns (
            uint8 status,
            uint256 opensAt,
            uint256 deadline,
            uint256 threshold,
            uint256 slotSize,
            uint256 seatCount,
            uint256 seatsFilled,
            uint256 committedTotal,
            uint256 tokensPerSeat
        )
    {
        return (WHITELIST_STATUS_NONE, 0, 0, 0, 0, 0, 0, 0, 0);
    }

    function isWhitelisted(address) public view virtual returns (bool) {
        return false;
    }

    function canCommitWhitelist(address) external view virtual returns (bool) {
        return false;
    }

    function canClaimWhitelistAllocation(address) external view virtual returns (bool) {
        return false;
    }

    function canClaimWhitelistRefund(address) external view virtual returns (bool) {
        return false;
    }

    function taxConfig()
        external
        view
        virtual
        returns (bool enabled, uint16 taxBps, uint16 burnShareBps, uint16 treasuryShareBps, address treasuryWallet, bool active)
    {
        return (false, 0, 0, 0, address(0), false);
    }

    function transfer(address to, uint256 value) public virtual override nonReentrant returns (bool) {
        if (value == 0) {
            return super.transfer(to, value);
        }
        if (state == LaunchState.Bonding314 && to == address(this)) {
            _beforeBondingAction();
            _sellFrom(_msgSender(), payable(_msgSender()), value, 0);
            return true;
        }
        if (state != LaunchState.DEXOnly) revert TransferDisabledPreGraduation();
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public virtual override nonReentrant returns (bool) {
        if (value == 0) {
            return super.transferFrom(from, to, value);
        }
        if (state == LaunchState.Bonding314 && to == address(this)) {
            _beforeBondingAction();
            if (_msgSender() != from) {
                _spendAllowance(from, _msgSender(), value);
            }
            _sellFrom(from, payable(from), value, 0);
            return true;
        }
        if (state != LaunchState.DEXOnly) {
            bool migrationPull = state == LaunchState.Migrating && from == address(this);
            if (!migrationPull) revert TransferDisabledPreGraduation();
        }
        return super.transferFrom(from, to, value);
    }

    function _beforeBondingAction() internal virtual {}

    function _additionalAccountedNative() internal view virtual returns (uint256) {
        return 0;
    }

    function _buyFrom(address buyer, address payable refundRecipient, uint256 minTokenOut) internal returns (uint256 tokenOut) {
        if (buyer == address(0) || buyer == address(this) || buyer == pair) {
            revert InvalidRecipient();
        }
        if (graduationAssistReady()) revert GraduationWindowFrozen();
        if (msg.value == 0) revert ZeroAmount();

        (uint256 usedGross, uint256 netQuoteIn, uint256 protocolFee, uint256 creatorFee) = _quoteBuy(msg.value);
        if (usedGross == 0 || netQuoteIn == 0) revert ZeroAmount();

        bool reachesGraduationBoundary = curveQuoteReserve + netQuoteIn == graduationQuoteReserve;
        tokenOut = _buyTokenOut(netQuoteIn);
        if (reachesGraduationBoundary) {
            tokenOut = saleTokenReserve;
        }

        if (tokenOut == 0 || tokenOut > saleTokenReserve) revert SlippageExceeded();
        if (tokenOut < minTokenOut) revert SlippageExceeded();

        curveQuoteReserve += netQuoteIn;
        protocolFeeVault += _allocateProtocolFee(protocolFee);
        creatorFeeVault += creatorFee;
        lastTradeAt = block.timestamp;
        saleTokenReserve -= tokenOut;

        _transfer(address(this), buyer, tokenOut);
        lastBuyBlock[buyer] = block.number;

        uint256 refundAmount = msg.value - usedGross;
        if (refundAmount > 0) {
            refundRecipient.sendValue(refundAmount);
        }

        emit BuyExecuted(
            buyer,
            usedGross,
            netQuoteIn,
            protocolFee,
            creatorFee,
            refundAmount,
            tokenOut,
            curveQuoteReserve,
            saleTokenReserve
        );

        if (curveQuoteReserve >= graduationQuoteReserve || saleTokenReserve == 0) {
            _graduate();
        } else {
            _tryUseGraduationAssist();
        }
    }

    function _sellFrom(address seller, address payable payoutRecipient, uint256 tokenAmount, uint256 minQuoteOut)
        internal
        returns (uint256 netQuoteOut)
    {
        if (state != LaunchState.Bonding314) revert InvalidState();
        if (graduationAssistReady()) revert GraduationWindowFrozen();
        if (tokenAmount == 0) revert ZeroAmount();
        if (lastBuyBlock[seller] == block.number) revert SellCooldownActive();

        (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) = _effectiveReserves();
        uint256 invariant = effectiveQuoteReserve * effectiveTokenReserve;
        uint256 newEffectiveTokenReserve = effectiveTokenReserve + tokenAmount;
        uint256 newEffectiveQuoteReserve = Math.ceilDiv(invariant, newEffectiveTokenReserve);
        uint256 grossQuoteOut = effectiveQuoteReserve - newEffectiveQuoteReserve;

        if (grossQuoteOut == 0 || grossQuoteOut > curveQuoteReserve) revert SlippageExceeded();

        (uint256 totalFee, uint256 protocolFee, uint256 creatorFee) = _splitFees(grossQuoteOut);
        netQuoteOut = grossQuoteOut - totalFee;
        if (netQuoteOut == 0) revert SlippageExceeded();
        if (netQuoteOut < minQuoteOut) revert SlippageExceeded();

        _transfer(seller, address(this), tokenAmount);

        saleTokenReserve += tokenAmount;
        curveQuoteReserve -= grossQuoteOut;
        protocolFeeVault += _allocateProtocolFee(protocolFee);
        creatorFeeVault += creatorFee;
        lastTradeAt = block.timestamp;

        payoutRecipient.sendValue(netQuoteOut);

        emit SellExecuted(
            seller,
            tokenAmount,
            grossQuoteOut,
            netQuoteOut,
            protocolFee,
            creatorFee,
            curveQuoteReserve,
            saleTokenReserve
        );
    }

    function _quoteBuy(uint256 grossQuoteIn)
        internal
        view
        returns (uint256 usedGross, uint256 netQuoteIn, uint256 protocolFee, uint256 creatorFee)
    {
        uint256 remainingCapacity = graduationQuoteReserve - curveQuoteReserve;
        if (remainingCapacity == 0) revert GraduationAlreadyTriggered();

        (uint256 tentativeFee,,) = _splitFees(grossQuoteIn);
        uint256 tentativeNet = grossQuoteIn - tentativeFee;

        if (tentativeNet <= remainingCapacity) {
            usedGross = grossQuoteIn;
            netQuoteIn = tentativeNet;
        } else {
            usedGross = Math.mulDiv(
                remainingCapacity,
                BPS_DENOMINATOR,
                BPS_DENOMINATOR - TOTAL_FEE_BPS,
                Math.Rounding.Ceil
            );

            while (usedGross > 0) {
                (uint256 feeCheck,,) = _splitFees(usedGross);
                uint256 netCheck = usedGross - feeCheck;
                if (netCheck <= remainingCapacity) {
                    break;
                }
                usedGross -= 1;
            }

            (uint256 finalFeeCheck,,) = _splitFees(usedGross);
            netQuoteIn = usedGross - finalFeeCheck;
        }

        (, protocolFee, creatorFee) = _splitFees(usedGross);
    }

    function _graduate() internal {
        if (state != LaunchState.Bonding314) revert InvalidState();
        if (curveQuoteReserve != graduationQuoteReserve) revert SlippageExceeded();

        LaunchState previousState = state;
        state = LaunchState.Migrating;
        emit StateTransition(previousState, LaunchState.Migrating);

        uint256 preloadedQuoteAmount = _preparePairForGraduation();

        uint256 tokenAmount = lpTokenReserve;
        uint256 quoteAmount = curveQuoteReserve - preloadedQuoteAmount;

        _transfer(address(this), pair, tokenAmount);
        if (quoteAmount != 0) {
            IWrappedNative(wrappedNative).deposit{value: quoteAmount}();
            bool wrappedTransferOk = IWrappedNative(wrappedNative).transfer(pair, quoteAmount);
            if (!wrappedTransferOk) revert WrappedQuoteTransferFailed();
        }

        uint256 liquidityBurned = IUniswapV2LikePair(pair).mint(DEAD_ADDRESS);

        lpTokenReserve = 0;
        uint256 reclaimedAssist = graduationAssistReserve;
        if (reclaimedAssist != 0) {
            graduationAssistReserve = 0;
            protocolFeeVault += reclaimedAssist;
            emit GraduationAssistReclaimed(reclaimedAssist, protocolFeeVault);
        }
        protocolFeeVault += preloadedQuoteAmount;
        curveQuoteReserve = 0;

        previousState = state;
        state = LaunchState.DEXOnly;
        emit StateTransition(previousState, LaunchState.DEXOnly);
        emit Graduated(pair, tokenAmount, quoteAmount, preloadedQuoteAmount, liquidityBurned);
    }

    function _accountedNativeBalance() internal view returns (uint256) {
        return curveQuoteReserve + protocolFeeVault + creatorFeeVault + graduationAssistReserve + _additionalAccountedNative();
    }

    function _remainingQuoteCapacity() internal view returns (uint256) {
        if (curveQuoteReserve >= graduationQuoteReserve) {
            return 0;
        }
        return graduationQuoteReserve - curveQuoteReserve;
    }

    function _allocateProtocolFee(uint256 protocolFee) internal returns (uint256 vaultAmount) {
        vaultAmount = protocolFee;
        if (protocolFee == 0) {
            return 0;
        }

        if (graduationAssistReserve >= GRADUATION_ASSIST_THRESHOLD) {
            return vaultAmount;
        }

        uint256 reserveNeeded = GRADUATION_ASSIST_THRESHOLD - graduationAssistReserve;
        uint256 reserveAmount = protocolFee < reserveNeeded ? protocolFee : reserveNeeded;
        if (reserveAmount == 0) {
            return vaultAmount;
        }

        graduationAssistReserve += reserveAmount;
        vaultAmount -= reserveAmount;

        emit GraduationAssistFunded(reserveAmount, graduationAssistReserve);
    }

    function _tryUseGraduationAssist() internal returns (bool graduated) {
        if (!graduationAssistReady()) {
            return false;
        }

        uint256 remaining = _remainingQuoteCapacity();
        graduationAssistReserve -= remaining;
        curveQuoteReserve += remaining;

        emit GraduationAssistTriggered(remaining, graduationAssistReserve);
        _graduate();
        return true;
    }

    function _unexpectedNativeBalance() internal view returns (uint256 amount) {
        uint256 accounted = _accountedNativeBalance();
        uint256 actualBalance = address(this).balance;
        if (actualBalance <= accounted) {
            return 0;
        }
        return actualBalance - accounted;
    }

    function _preparePairForGraduation() internal returns (uint256 preloadedQuoteAmount) {
        if (pair == address(0)) revert PairPolluted();

        IUniswapV2LikePair lpPair = IUniswapV2LikePair(pair);
        if (lpPair.totalSupply() != 0) revert PairPolluted();

        (uint112 reserve0, uint112 reserve1,) = lpPair.getReserves();
        address token0 = lpPair.token0();
        address token1 = lpPair.token1();

        uint256 tokenReserve;
        uint256 wrappedReserve;
        if (token0 == address(this)) {
            tokenReserve = reserve0;
            wrappedReserve = reserve1;
        } else if (token1 == address(this)) {
            tokenReserve = reserve1;
            wrappedReserve = reserve0;
        } else {
            revert PairPolluted();
        }

        if (tokenReserve != 0) revert PairPolluted();

        uint256 tokenBalanceAtPair = balanceOf(pair);
        if (tokenBalanceAtPair != 0) revert PairPolluted();

        uint256 wrappedBalanceAtPair = IERC20Minimal(wrappedNative).balanceOf(pair);
        if (wrappedBalanceAtPair < wrappedReserve) revert PairPolluted();

        preloadedQuoteAmount = wrappedBalanceAtPair;
        if (preloadedQuoteAmount > graduationQuoteReserve) revert PairPolluted();
    }

    function _graduationPathHealthy() internal view returns (bool) {
        if (pair == address(0)) return false;

        IUniswapV2LikePair lpPair = IUniswapV2LikePair(pair);
        if (lpPair.totalSupply() != 0) return false;

        (uint112 reserve0, uint112 reserve1,) = lpPair.getReserves();
        address token0 = lpPair.token0();
        address token1 = lpPair.token1();

        uint256 tokenReserve;
        uint256 wrappedReserve;
        if (token0 == address(this)) {
            tokenReserve = reserve0;
            wrappedReserve = reserve1;
        } else if (token1 == address(this)) {
            tokenReserve = reserve1;
            wrappedReserve = reserve0;
        } else {
            return false;
        }

        if (tokenReserve != 0) return false;
        if (balanceOf(pair) != 0) return false;

        uint256 wrappedBalanceAtPair = IERC20Minimal(wrappedNative).balanceOf(pair);
        if (wrappedBalanceAtPair < wrappedReserve) return false;
        if (wrappedBalanceAtPair > graduationQuoteReserve) return false;
        return true;
    }

    function _buyTokenOut(uint256 netQuoteIn) internal view returns (uint256 tokenOut) {
        if (curveQuoteReserve + netQuoteIn == graduationQuoteReserve) {
            return saleTokenReserve;
        }

        (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) = _effectiveReserves();
        uint256 invariant = effectiveQuoteReserve * effectiveTokenReserve;
        uint256 newEffectiveQuoteReserve = effectiveQuoteReserve + netQuoteIn;
        uint256 newEffectiveTokenReserve = invariant / newEffectiveQuoteReserve;
        tokenOut = effectiveTokenReserve - newEffectiveTokenReserve;
    }

    function _effectiveReserves() internal view returns (uint256 effectiveQuoteReserve, uint256 effectiveTokenReserve) {
        effectiveQuoteReserve = curveQuoteReserve + virtualQuoteReserve;
        effectiveTokenReserve = saleTokenReserve + lpTokenReserve + virtualTokenReserve;
    }

    function _dexReserves() internal view returns (uint256 tokenReserve, uint256 quoteReserve) {
        if (pair == address(0)) {
            return (0, 0);
        }

        IUniswapV2LikePair lpPair = IUniswapV2LikePair(pair);
        (uint112 reserve0, uint112 reserve1,) = lpPair.getReserves();
        address token0 = lpPair.token0();

        if (token0 == address(this)) {
            tokenReserve = reserve0;
            quoteReserve = reserve1;
        } else {
            tokenReserve = reserve1;
            quoteReserve = reserve0;
        }
    }

    function _splitFees(uint256 grossAmount)
        internal
        pure
        returns (uint256 totalFee, uint256 protocolFee, uint256 creatorFee)
    {
        if (grossAmount == 0) {
            return (0, 0, 0);
        }

        totalFee = Math.mulDiv(grossAmount, TOTAL_FEE_BPS, BPS_DENOMINATOR, Math.Rounding.Ceil);
        protocolFee = Math.mulDiv(totalFee, PROTOCOL_FEE_BPS, TOTAL_FEE_BPS);
        creatorFee = totalFee - protocolFee;
    }

    function _creatorFeeSweepReady() internal view returns (bool) {
        return state == LaunchState.Bonding314
            && creatorFeeVault > 0
            && block.timestamp >= createdAt + CREATOR_FEE_SWEEP_MIN_AGE
            && block.timestamp >= lastTradeAt + CREATOR_FEE_SWEEP_MIN_INACTIVITY;
    }

    function _ensurePair() internal returns (address ensuredPair) {
        ensuredPair = IUniswapV2LikeFactory(dexFactory).getPair(address(this), wrappedNative);
        if (ensuredPair == address(0)) {
            ensuredPair = IUniswapV2LikeFactory(dexFactory).createPair(address(this), wrappedNative);
        }
    }

    function _update(address from, address to, uint256 value) internal virtual override {
        if (value == 0) {
            super._update(from, to, value);
            return;
        }

        if (state == LaunchState.Bonding314 || state == LaunchState.WhitelistCommit) {
            bool isMintOrBurn = from == address(0) || to == address(0);
            bool isProtocolTransfer = from == address(this) || to == address(this);
            if (!isMintOrBurn && !isProtocolTransfer) {
                revert TransferDisabledPreGraduation();
            }
        } else if (state == LaunchState.Migrating) {
            bool migrationAllowed = from == address(this);
            if (!migrationAllowed) {
                revert InvalidState();
            }
        } else if (state == LaunchState.DEXOnly) {
            if (to == address(this)) {
                revert InvalidRecipient();
            }
        }

        if (from != address(0) && from != address(this) && value != 0) {
            hasTransferredOut[from] = true;
        }

        super._update(from, to, value);
    }
}

interface IERC20Minimal {
    function balanceOf(address account) external view returns (uint256);
}

interface IWrappedNative is IERC20Minimal {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
}
