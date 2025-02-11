// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

interface IUniswapFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}
