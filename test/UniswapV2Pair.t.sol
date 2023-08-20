// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/libraries/UQ112x112.sol";
import "./mocks/MockERC20.sol";

contract UniswapV2PairTest is Test {
    MockERC20 token0;
    MockERC20 token1;
    UniswapV2Pair pair;
    TestUser testUser;

    function setUp() public {
        testUser = new TestUser();
        token0 = new MockERC20("Token A", "TKNA");
        token1 = new MockERC20("Token B", "TKNB");
        UniswapV2Factory factory = new UniswapV2Factory();
        address pairAddress = factory.createPair(
            address(token0),
            address(token1)
        );
        pair = UniswapV2Pair(pairAddress);

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        token0.mint(10 ether, address(testUser));
        token1.mint(10 ether, address(testUser));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }
}

contract TestUser {
    function providerLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);
        UniswapV2Pair(pairAddress_).mint(address(this));
    }

    function removeLiquidity(address pairAddress_) public {
        uint256 liquidity = ERC20(pairAddress_).balanceOf(address(this));
        ERC20(pairAddress_).transfer(pairAddress_, liquidity);
        UniswapV2Pair(pairAddress_).burn(address(this));
    }
}
