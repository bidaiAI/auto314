// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {MockDexV2Factory} from "./MockDexV2Factory.sol";
import {MockDexV2Pair} from "./MockDexV2Pair.sol";
import {MockERC20} from "./MockERC20.sol";

interface IERC20Transfer {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MockDexV2Router {
    address public immutable factory;
    address public immutable WETH;

    constructor(address factory_, address wrappedNative_) {
        factory = factory_;
        WETH = wrappedNative_;
    }

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity) {
        amountTokenMin;
        amountETHMin;
        deadline;

        address pair = MockDexV2Factory(factory).getPair(token, WETH);
        require(pair != address(0), "PAIR_NOT_FOUND");

        IERC20Transfer(token).transferFrom(msg.sender, pair, amountTokenDesired);
        MockERC20(WETH).mint(pair, msg.value);

        amountToken = amountTokenDesired;
        amountETH = msg.value;
        liquidity = MockDexV2Pair(pair).initializeLiquidityFromBalances(to);
    }

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable {
        uint256 balanceBefore = IERC20Transfer(path[1]).balanceOf(to);
        _swapExactETHForTokens(path, to, deadline);
        uint256 balanceAfter = IERC20Transfer(path[1]).balanceOf(to);
        require(balanceAfter - balanceBefore >= amountOutMin, "INSUFFICIENT_OUTPUT");
    }

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts) {
        uint256 amountOut = _swapExactETHForTokens(path, to, deadline);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT");
        amounts = new uint256[](2);
        amounts[0] = msg.value;
        amounts[1] = amountOut;
    }

    function _swapExactETHForTokens(address[] calldata path, address to, uint256 deadline)
        internal
        returns (uint256 amountOut)
    {
        require(path.length == 2, "INVALID_PATH");
        require(path[0] == WETH, "INVALID_INPUT");
        require(block.timestamp <= deadline, "EXPIRED");

        address pair = MockDexV2Factory(factory).getPair(path[0], path[1]);
        require(pair != address(0), "PAIR_NOT_FOUND");

        MockERC20(WETH).deposit{value: msg.value}();
        IERC20Transfer(WETH).transfer(pair, msg.value);

        MockDexV2Pair pairContract = MockDexV2Pair(pair);
        (uint112 reserve0, uint112 reserve1,) = pairContract.getReserves();
        address token0 = pairContract.token0();

        uint256 reserveIn;
        uint256 reserveOut;
        bool outputIsToken0 = path[1] == token0;
        if (path[0] == token0) {
            reserveIn = uint256(reserve0);
            reserveOut = uint256(reserve1);
        } else {
            reserveIn = uint256(reserve1);
            reserveOut = uint256(reserve0);
        }

        uint256 amountInWithFee = msg.value * 997;
        amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);
        require(amountOut > 0, "INSUFFICIENT_OUTPUT");

        if (outputIsToken0) {
            pairContract.swap(amountOut, 0, to);
        } else {
            pairContract.swap(0, amountOut, to);
        }
    }
}
