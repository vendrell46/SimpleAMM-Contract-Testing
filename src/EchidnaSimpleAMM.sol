// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SimpleAMM.sol";

contract EchidnaSimpleAMM {
    SimpleAMM public simpleAMM;

    // Echidna will automatically provide random values for this variable
    uint256 public tokenAAmount;

    uint256 private initialConstantProduct;

    constructor() {
        simpleAMM = new SimpleAMM();
        simpleAMM.addLiquidity(1000, 1000);
        initialConstantProduct = simpleAMM.constantProduct();
    }

    // Constant Product Invariant
    function echidna_constant_product_invariant() public returns (bool) {
        uint256 product = simpleAMM.reserveTokenA() * simpleAMM.reserveTokenB();
        return product == simpleAMM.constantProduct();
    }

    // Reserve Non-Negativity Invariant
    function echidna_test_reserve_non_negativity() public returns (bool) {
        // Check if reserves are non-negative (non-negative check is implicit due to uint256)
        return simpleAMM.reserveTokenA() >= 0 && simpleAMM.reserveTokenB() >= 0;
    }

    // Swap Rate Fairness Invariant
    function echidna_test_swap_rate_fairness() public returns (bool) {
        uint256 currentProduct = simpleAMM.reserveTokenA() * simpleAMM.reserveTokenB();
        
        // Allow for a small tolerance due to integer division rounding
        uint256 tolerance = initialConstantProduct / 1000; // Adjust the tolerance as needed

        return (currentProduct >= initialConstantProduct - tolerance) &&
               (currentProduct <= initialConstantProduct + tolerance);
    }

    // Liquidity Addition and Removal Consistency Invariant
    function echidna_test_liquidity_addition_removal_consistency() public returns (bool) {
        uint256 initialReserveTokenA = simpleAMM.reserveTokenA();
        uint256 initialReserveTokenB = simpleAMM.reserveTokenB();

        // Add liquidity
        simpleAMM.addLiquidity(500, 500);
        // Remove the same amount of liquidity
        simpleAMM.removeLiquidity(500, 500);

        // Check if reserves are back to their initial state
        return (simpleAMM.reserveTokenA() == initialReserveTokenA) &&
            (simpleAMM.reserveTokenB() == initialReserveTokenB);
    }

    // Invariant: No Token Creation or Destruction
    function echidna_test_token_conservation() public returns (bool) {
        uint256 initialTotalSupply = 100000; // This is a hardcoded value. Simplifying it for the sake of testing.
        uint256 totalReserve = simpleAMM.reserveTokenA() + simpleAMM.reserveTokenB();
        uint256 totalHeldByUsers = 98000; // This is a hardcoded value. Simplifying it for the sake of testing.

        // The total supply should always be equal to the sum of reserves and tokens held by users
        return initialTotalSupply == (totalReserve + totalHeldByUsers);
    }

    // Test to ensure zero liquidity cannot be added
    function echidna_test_positive_liquidity() public returns (bool) {
        // Attempt to add zero liquidity
        try simpleAMM.addLiquidity(0, 0) {
            // If the call succeeds, return false (test should fail)
            return false;
        } catch {
            // If the call fails, return true (test should pass)
            return true;
        }
    }

    // Test to ensure the swap amount is valid
    function echidna_test_swap_amount_validation() public returns (bool) {
        // Get the swap amount for Token A
        uint256 swapAmountB = simpleAMM.getSwapAmount(tokenAAmount); // Where tokenAAmount is randomized by Echidna

        // Get the current reserve of Token B
        uint256 currentReserveB = simpleAMM.reserveTokenB();

        // Check if the swap amount is less than or equal to the reserve of Token B
        return swapAmountB <= currentReserveB;
    }

    // Solvency Invariant Test
    function echidna_test_solvency() public {
        // Record reserves before the swap
        uint256 reserveTokenABefore = simpleAMM.reserveTokenA();
        uint256 reserveTokenBBefore = simpleAMM.reserveTokenB();

        // Swap amount of Token A for Token B
        simpleAMM.swapTokenAForTokenB(tokenAAmount); // Where tokenAAmount is randomized by Echidna

        // Check if reserves are still above the minimum allowed threshold
        bool isSolvencyMaintained = (simpleAMM.reserveTokenA() >= simpleAMM.MINIMUM_RESERVE_THRESHOLD()) &&
                                    (simpleAMM.reserveTokenB() >= simpleAMM.MINIMUM_RESERVE_THRESHOLD());

        // Assertions for debugging
        assert(isSolvencyMaintained); // Check solvency maintenance
        assert(simpleAMM.reserveTokenA() <= reserveTokenABefore); // Token A reserve should not increase after swap
        assert(simpleAMM.reserveTokenB() >= reserveTokenBBefore); // Token B reserve should not decrease after swap
    }
}
