// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleAMM {
    uint256 public constant MINIMUM_RESERVE_THRESHOLD = 500;

    uint256 public reserveTokenA;
    uint256 public reserveTokenB;
    uint256 public constantProduct;

    event LiquidityAdded(
        address indexed user,
        uint256 tokenAAmount,
        uint256 tokenBAmount
    );
    event LiquidityRemoved(
        address indexed user,
        uint256 tokenAAmount,
        uint256 tokenBAmount
    );
    event TokensSwapped(
        address indexed user,
        uint256 tokenASwapped,
        uint256 tokenBReceived
    );
    event TokensToSwap(
        uint256 indexed tokenAToSwapp,
        uint256 indexed tokenBToReceive
    );

    function addLiquidity(uint256 tokenAAmount, uint256 tokenBAmount) external {
        require(
            tokenAAmount > 0 && tokenBAmount > 0,
            "Cannot add zero liquidity"
        );
        reserveTokenA += tokenAAmount;
        reserveTokenB += tokenBAmount;
        updateConstantProduct();
        emit LiquidityAdded(msg.sender, tokenAAmount, tokenBAmount);
    }

    function removeLiquidity(
        uint256 tokenAAmount,
        uint256 tokenBAmount
    ) external {
        require(
            reserveTokenA >= tokenAAmount && reserveTokenB >= tokenBAmount,
            "Insufficient liquidity"
        );
        reserveTokenA -= tokenAAmount;
        reserveTokenB -= tokenBAmount;

        // Check final reserves after swap
        require(
            reserveTokenA >= MINIMUM_RESERVE_THRESHOLD,
            "Reserve Token A below minimum threshold"
        );
        require(
            reserveTokenB >= MINIMUM_RESERVE_THRESHOLD,
            "Reserve Token B below minimum threshold"
        );

        updateConstantProduct();
        emit LiquidityRemoved(msg.sender, tokenAAmount, tokenBAmount);
    }

    function swapTokenAForTokenB(uint256 tokenAAmount) external {
        uint256 tokenBAmount = getSwapAmount(tokenAAmount);
        emit TokensToSwap(tokenAAmount, tokenBAmount);

        require(reserveTokenB >= tokenBAmount, "Insufficient token B reserve");
        reserveTokenA += tokenAAmount;
        reserveTokenB -= tokenBAmount;

        // Check final reserves after swap
        require(
            reserveTokenA >= MINIMUM_RESERVE_THRESHOLD,
            "Reserve Token A below minimum threshold"
        );
        require(
            reserveTokenB >= MINIMUM_RESERVE_THRESHOLD,
            "Reserve Token B below minimum threshold"
        );

        updateConstantProduct();
        emit TokensSwapped(msg.sender, tokenAAmount, tokenBAmount);
    }

    function getSwapAmount(uint256 tokenAAmount) public view returns (uint256) {
        uint256 newReserveA = reserveTokenA + tokenAAmount;
        require(newReserveA > 0, "Invalid swap amount");
        uint256 newReserveB = constantProduct / newReserveA;
        return reserveTokenB - newReserveB;
    }

    function updateConstantProduct() private {
        constantProduct = reserveTokenA * reserveTokenB;
    }
}
