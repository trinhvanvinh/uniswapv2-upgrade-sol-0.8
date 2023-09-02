// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "./mocks/MockERC20.sol";

contract MockERC20Test is Test {
    MockERC20 e;
    address owner;

    function setUp() public {
        owner = address(this);
        e = new MockERC20("Token", "TKN");
    }

    function testMint() public {
        e.mint(5000, owner);
        assertEq(e.balanceOf(owner), 5000);
    }
}
