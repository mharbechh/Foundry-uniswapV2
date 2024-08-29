// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IUniswap.sol";
import "./IUniswapFactory.sol";

contract LiquidityManager {
    address public constant UNISWAP_V2_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant UNISWAP_V2_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event LiquidityProvided(
        address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed tokenA, address indexed tokenB, uint256 liquidity, uint256 amountA, uint256 amountB
    );

    /**
     * @notice Provide liquidity to a Uniswap V2 pool
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param amountADesired The amount of tokenA you want to provide
     * @param amountBDesired The amount of tokenB you want to provide
     * @param amountAMin Minimum amount of tokenA to add (slippage protection)
     * @param amountBMin Minimum amount of tokenB to add (slippage protection)
     * @param to The address that will receive the liquidity tokens
     * @param deadline The transaction deadline (timestamp)
     */
    function provideLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(tokenA != address(0) && tokenB != address(0), "Invalid token address");
        require(amountADesired > 0 && amountBDesired > 0, "Invalid amounts");

        // Transfer tokens to this contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        // Approve tokens for Uniswap router
        IERC20(tokenA).approve(UNISWAP_V2_ROUTER, amountADesired);
        IERC20(tokenB).approve(UNISWAP_V2_ROUTER, amountBDesired);

        // Add liquidity to the Uniswap pool
        (amountA, amountB, liquidity) = IUniswap(UNISWAP_V2_ROUTER).addLiquidity(
            tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, to, deadline
        );

        emit LiquidityProvided(tokenA, tokenB, amountA, amountB, liquidity);
    }

    /**
     * @notice Remove liquidity from a Uniswap V2 pool
     * @param tokenA The address of the first token in the pair
     * @param tokenB The address of the second token in the pair
     * @param liquidity The amount of liquidity tokens to remove
     * @param amountAMin Minimum amount of tokenA to receive (slippage protection)
     * @param amountBMin Minimum amount of tokenB to receive (slippage protection)
     * @param to The address that will receive the withdrawn tokens
     * @param deadline The transaction deadline (timestamp)
     */
    function redeemShares(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB) {
        require(tokenA != address(0) && tokenB != address(0), "Invalid token address");
        require(liquidity > 0, "Invalid liquidity amount");

        // Get the pair address for the token pair
        address pair = IUniswapFactory(UNISWAP_V2_FACTORY).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");

        // Transfer liquidity tokens to this contract
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);

        // Approve liquidity tokens for Uniswap router
        IERC20(pair).approve(UNISWAP_V2_ROUTER, liquidity);

        // Remove liquidity from the Uniswap pool
        (amountA, amountB) =
            IUniswap(UNISWAP_V2_ROUTER).removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);

        emit LiquidityRemoved(tokenA, tokenB, liquidity, amountA, amountB);
    }
}
