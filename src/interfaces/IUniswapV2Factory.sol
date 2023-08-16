// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

interface IUniswapV2Factory {
    function pairs(address, address) external pure returns (address);

    function createPair(address, address) external returns (address);
}