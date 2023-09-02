// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Pair.sol";
import "../src/UniswapV2Router.sol";
import "./mocks/MockERC20.sol";
import "forge-std/console.sol";

contract UniswapV2RouterTest is Test {
    UniswapV2Factory factory;
    UniswapV2Router router;

    MockERC20 tokenA;
    MockERC20 tokenB;
    MockERC20 tokenC;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router(address(factory));

        tokenA = new MockERC20("Token A", "TKNA");
        tokenB = new MockERC20("Token B", "TKNB");
        tokenC = new MockERC20("Token C", "TKNC");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
        tokenC.mint(20 ether, address(this));
    }

    function encodeError(
        string memory error
    ) internal pure returns (bytes memory encoded) {
        encoded = abi.encodeWithSignature(error);
    }

    function testAddLiquidityCreatePair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        (bool success, ) = address(router).call(
            abi.encodeWithSelector(
                router.addLiquidity.selector,
                address(tokenA),
                address(tokenB),
                1 ether,
                1 ether,
                1 ether,
                1 ether,
                address(this)
            )
        );
        console.log("router %s", success);
        assertTrue(success, "Failed to add Liquidity");
    }
}
