// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IUniswapV2Callee {
    function UniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external;
}
