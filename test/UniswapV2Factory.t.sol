// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "./mocks/MockERC20.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";

contract UniswapV2FactoryTest is Test {
    UniswapV2Factory factory;
    MockERC20 mocktoken0;
    MockERC20 mocktoken1;

    function setUp() public {
        factory = new UniswapV2Factory();
        mocktoken0 = new MockERC20("Token A", "TKNA");
        mocktoken1 = new MockERC20("Token B", "TKNB");
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testCreatePair() public {
        address pairAddress = factory.createPair(
            address(mocktoken0),
            address(mocktoken1)
        );
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        assertEq(pair.token0(), address(mocktoken0));
        assertEq(pair.token1(), address(mocktoken1));
    }

    function testCreatePairZeroAddress() public {
        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(0), address(mocktoken0));

        vm.expectRevert(encodeError("ZeroAddress()"));
        factory.createPair(address(mocktoken1), address(mocktoken0));
    }

    function testCreatePairPairExists() public {
        factory.createPair(address(mocktoken0), address(mocktoken1));
        vm.expectRevert(encodeError("PairExists()"));
        factory.createPair(address(mocktoken0), address(mocktoken1));
    }

    function testCreatePairIdeticalTokens() public {
        vm.expectRevert(encodeError("IdenticalAddresses()"));
        factory.createPair(address(mocktoken0), address(mocktoken0));
    }
}
