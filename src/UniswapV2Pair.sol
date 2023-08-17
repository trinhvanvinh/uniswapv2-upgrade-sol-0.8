// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "../lib/solmate/src/tokens/ERC20.sol";
import "./interfaces/IUniswapV2Callee.sol";
import "./libraries/Math.sol";
import "./libraries/UQ112x112.sol";

interface IERC20 {
    function balanceOf(address) external returns (uint256);

    function transfer(address to, uint256 amount) external;
}

contract UniswapV2Pair is ERC20, Math {
    using UQ112x112 for uint224;
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    address public token0;
    address public token1;

    uint112 private reserve0;
    uint112 private reserve1;
    uint32 private blockTimestampLast;

    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;

    bool private isEntered;
    modifier nonReentrant() {
        require(!isEntered);
        isEntered = true;
        _;
        isEntered = false;
    }

    // events
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address to
    );

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);

    event Sync(uint256 reserve0, uint256 reserve1);
    event Swap(
        address indexed sender,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );

    constructor() ERC20("UniswapV2 Pair", "ZUNIV2", 18) {}

    function initialize(address token0_, address token1_) public {
        require(
            token0 != address(0) || token1 != address(0),
            "token is not address(0)"
        );
        token0 = token0_;
        token1 = token1_;
    }

    function sync() public {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        _update(
            IERC20(token0).balanceOf(address(this)),
            IERC20(token1).balanceOf(address(this)),
            reserve0_,
            reserve1_
        );
    }

    function getReserves() public view returns (uint112, uint112, uint32) {
        return (reserve0, reserve1, blockTimestampLast);
    }

    function _update(
        uint256 balance0,
        uint256 balance1,
        uint112 reserve0_,
        uint112 reserve1_
    ) private {
        unchecked {
            uint32 timeElapsed = uint32(block.timestamp) - blockTimestampLast;
            if (timeElapsed > 0 && reserve0_ > 0 && reserve1_ > 0) {
                price0CumulativeLast +=
                    uint256(UQ112x112.encode(reserve1_).uqdiv(reserve0_)) *
                    timeElapsed;
                price1CumulativeLast +=
                    uint256(UQ112x112.encode(reserve0_).uqdiv(reserve1_)) *
                    timeElapsed;
            }
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = uint32(block.timestamp);

        emit Sync(reserve0, reserve1);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, value)
        );
        require(
            !success || (data.length != 0 && !abi.decode(data, (bool))),
            "Transfer failed"
        );
    }

    function mint(address to) public returns (uint256 liquidity) {
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 amount0 = balance0 - reserve0_;
        uint256 amount1 = balance1 - reserve1_;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0_,
                (amount1 * totalSupply) / reserve1_
            );
        }
        require(liquidity > 0, "Insufficient liquidity minted");
        _mint(to, liquidity);
        _update(balance0, balance1, reserve0_, reserve1_);
        emit Mint(to, amount0, amount1);
    }

    function burn(
        address to
    ) public returns (uint256 amount0, uint256 amount1) {
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));
        uint256 liquidity = balanceOf[address(this)];

        amount0 = (liquidity * balance0) / totalSupply;
        amount1 = (liquidity * balance1) / totalSupply;

        require(amount0 > 0 || amount1 > 0, "Insufficient Liquidity Burned");
        _burn(address(this), liquidity);

        _safeTransfer(token0, to, amount0);
        _safeTransfer(token1, to, amount1);

        balance0 = IERC20(token0).balanceOf(address(this));
        balance1 = IERC20(token1).balanceOf(address(this));

        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        _update(balance0, balance1, reserve0_, reserve1_);

        emit Burn(msg.sender, amount0, amount1, to);
    }

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) public nonReentrant {
        require(amount0Out > 0 || amount1Out > 0, "Insufficient output amount");
        (uint112 reserve0_, uint112 reserve1_, ) = getReserves();
        require(
            amount0Out < reserve0_ && amount1Out < reserve1_,
            "Insufficient liquditiy"
        );
        if (amount0Out > 0) _safeTransfer(token0, to, amount0Out);
        if (amount1Out > 0) _safeTransfer(token1, to, amount1Out);
        if (data.length > 0) {
            IUniswapV2Callee(to).UniswapV2Call(
                msg.sender,
                amount0Out,
                amount1Out,
                data
            );
        }
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        uint256 amount0In = balance0 > reserve0 - amount0Out
            ? balance0 - (reserve0 - amount0Out)
            : 0;
        uint256 amount1In = balance1 > reserve1 - amount1Out
            ? balance1 - (reserve1 - amount1Out)
            : 0;
        require(amount0In > 0 || amount1In > 0, "Insufficient input amount");

        uint256 balance0Adjted = (balance0 * 1000) - (amount0In * 3);
        uint256 balance1Adjted = (balance1 * 1000) - (amount1In * 3);

        require(
            balance0Adjted * balance1Adjted >=
                reserve0_ * reserve1_ * (1000 ** 2),
            "Invalid K"
        );
        _update(balance0, balance1, reserve0_, reserve1_);
        emit Swap(msg.sender, amount0Out, amount1Out, to);
    }
}
