// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import {Test, console} from "forge-std/Test.sol";
import "../src/LiquidityManager.sol";
import "../src/IERC20.sol";

contract LiquidityManagerTest is Test {
    LiquidityManager liquidityManager;
    address whale = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address tokenA = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
    address tokenB = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH
    IERC20 contractTokenA;
    IERC20 contractTokenB;
    uint256 amountD_A = 7000 * 1e18; // Assuming 18 decimals for DAI
    uint256 amountD_B = 2 * 1e18; // Assuming 18 decimals for WETH
    uint256 amountA_Min = 1;
    uint256 amountB_Min = 1;
    address to = whale;
    uint256 deadline = block.timestamp;

    function setUp() public {
        liquidityManager = new LiquidityManager();
        contractTokenA = IERC20(tokenA);
        contractTokenB = IERC20(tokenB);
        vm.startPrank(whale);
        IERC20(tokenA).approve(address(liquidityManager), amountD_A);
        IERC20(tokenB).approve(address(liquidityManager), amountD_B);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.prank(whale);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = liquidityManager.provideLiquidity(
            tokenA, tokenB, amountD_A, amountD_B, amountA_Min, amountB_Min, to, deadline
        );

        // Check event logs
        // vm.expectEmit(true, true, true, true);
        // emit LiquidityManager.LiquidityProvided(tokenA, tokenB, amountA, amountB, liquidity);

        // Ensure correct amounts and liquidity are returned
        assertLt(amountA, amountD_A);
        assertEq(amountB, amountD_B);
        assertGt(liquidity, 0);

        console.log("Liquidity tokens received: ", liquidity);
    }

    function testRemoveLiquidity() public {
        vm.startPrank(whale);

        // First add liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = liquidityManager.provideLiquidity(
            tokenA, tokenB, amountD_A, amountD_B, amountA_Min, amountB_Min, to, deadline
        );

        console.log("Amount of token A provided: ", amountA);
        console.log("Amount of token B provided: ", amountB);
        console.log("Liquidity tokens received: ", liquidity);

        // Fetch the pair address for tokenA and tokenB
        address pair = IUniswapFactory(liquidityManager.UNISWAP_V2_FACTORY()).getPair(tokenA, tokenB);
        require(pair != address(0), "Pair does not exist");

        // Check how many liquidity tokens we have and approve that exact amount
        uint256 liquidityBalance = IERC20(pair).balanceOf(whale);
        console.log("Liquidity tokens available to burn: ", liquidityBalance);

        // Approve exactly the liquidity tokens we have
        IERC20(pair).approve(address(liquidityManager), liquidityBalance);

        vm.stopPrank();

        // Now remove liquidity using the approved amount
        vm.prank(whale);
        (uint256 amount_A, uint256 amount_B) =
            liquidityManager.redeemShares(tokenA, tokenB, liquidityBalance, amountA_Min, amountB_Min, to, deadline);

        console.log("Liquidity removed, and tokens returned.");
        console.log("Amount of DAI (tokenA) received: ", amount_A);
        console.log("Amount of WETH (tokenB) received: ", amount_B);

        // Ensure amounts are non-zero
        assertGt(amount_A, 0, "Expected non-zero amount of token A");
        assertGt(amount_B, 0, "Expected non-zero amount of token B");
    }
}
