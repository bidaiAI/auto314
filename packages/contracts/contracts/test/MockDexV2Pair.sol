// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20Like {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract MockDexV2Pair {
    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    address public immutable factory;
    address public immutable token0;
    address public immutable token1;
    uint256 public totalSupply;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    mapping(address => uint256) public balanceOf;

    constructor(address token0_, address token1_) {
        factory = msg.sender;
        token0 = token0_;
        token1 = token1_;
    }

    function getReserves() external view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function initializeLiquidity(uint256 amount0, uint256 amount1, uint256 liquidity, address to) external {
        require(totalSupply == 0, "PAIR_INITIALIZED");
        _accrueCumulative();
        reserve0 = uint112(amount0);
        reserve1 = uint112(amount1);
        blockTimestampLast = _currentBlockTimestamp();
        totalSupply = liquidity;
        balanceOf[to] += liquidity;
    }

    function initializeLiquidityFromBalances(address to) external returns (uint256 liquidity) {
        require(totalSupply == 0, "PAIR_INITIALIZED");

        uint256 balance0Current = IERC20Like(token0).balanceOf(address(this));
        uint256 balance1Current = IERC20Like(token1).balanceOf(address(this));

        require(balance0Current > 0 && balance1Current > 0, "INSUFFICIENT_BALANCE");

        _accrueCumulative();
        reserve0 = uint112(balance0Current);
        reserve1 = uint112(balance1Current);
        blockTimestampLast = _currentBlockTimestamp();
        liquidity = balance0Current < balance1Current ? balance0Current : balance1Current;
        totalSupply = liquidity;
        balanceOf[to] += liquidity;
    }

    function mint(address to) external returns (uint256 liquidity) {
        _accrueCumulative();
        uint256 balance0Current = IERC20Like(token0).balanceOf(address(this));
        uint256 balance1Current = IERC20Like(token1).balanceOf(address(this));

        uint256 amount0 = balance0Current - reserve0;
        uint256 amount1 = balance1Current - reserve1;
        require(amount0 > 0 && amount1 > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        liquidity = amount0 < amount1 ? amount0 : amount1;
        require(liquidity > 0, "INSUFFICIENT_LIQUIDITY_MINTED");

        totalSupply += liquidity;
        balanceOf[to] += liquidity;
        reserve0 = uint112(balance0Current);
        reserve1 = uint112(balance1Current);
        blockTimestampLast = _currentBlockTimestamp();
    }

    function swap(uint256 amount0Out, uint256 amount1Out, address to) external {
        require(amount0Out > 0 || amount1Out > 0, "INSUFFICIENT_OUTPUT");
        require(amount0Out < reserve0 && amount1Out < reserve1, "INSUFFICIENT_LIQUIDITY");

        if (amount0Out != 0) {
            IERC20Like(token0).transfer(to, amount0Out);
        }
        if (amount1Out != 0) {
            IERC20Like(token1).transfer(to, amount1Out);
        }

        _accrueCumulative();
        reserve0 = uint112(IERC20Like(token0).balanceOf(address(this)));
        reserve1 = uint112(IERC20Like(token1).balanceOf(address(this)));
        blockTimestampLast = _currentBlockTimestamp();
    }

    function skim(address to) external {
        uint256 balance0Current = IERC20Like(token0).balanceOf(address(this));
        uint256 balance1Current = IERC20Like(token1).balanceOf(address(this));

        uint256 excess0 = balance0Current > reserve0 ? balance0Current - reserve0 : 0;
        uint256 excess1 = balance1Current > reserve1 ? balance1Current - reserve1 : 0;

        IERC20Like(token0).transfer(to, excess0);
        IERC20Like(token1).transfer(to, excess1);
    }

    function setReserves(uint112 reserve0_, uint112 reserve1_) external {
        _accrueCumulative();
        reserve0 = reserve0_;
        reserve1 = reserve1_;
        blockTimestampLast = _currentBlockTimestamp();
    }

    function setTotalSupply(uint256 totalSupply_) external {
        totalSupply = totalSupply_;
    }

    function syncCumulative() external {
        _accrueCumulative();
        blockTimestampLast = _currentBlockTimestamp();
    }

    function _accrueCumulative() internal {
        uint32 currentTimestamp = _currentBlockTimestamp();
        uint32 timeElapsed = currentTimestamp - blockTimestampLast;
        if (timeElapsed == 0 || reserve0 == 0 || reserve1 == 0) {
            return;
        }

        price0CumulativeLast += ((uint256(reserve1) << 112) / uint256(reserve0)) * timeElapsed;
        price1CumulativeLast += ((uint256(reserve0) << 112) / uint256(reserve1)) * timeElapsed;
    }

    function _currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }
}
