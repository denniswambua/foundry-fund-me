// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";

import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address user = makeAddr("Alice");
    uint256 amount = 0.1 ether;
    uint256 starting_balance = 1 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(user, starting_balance);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwner() public {
        assertEq(fundme.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public {
        assertEq(fundme.getVersion(), 4);
    }

    function testsFundsFailsWithLessAmount() public {
        vm.expectRevert();
        fundme.fund();
    }

    modifier funded() {
        vm.prank(user);
        fundme.fund{value: amount}();
        _;
    }

    function testFundUpdates() public funded {
        uint256 amountFunded = fundme.getAddressToAmountFunded(user);
        assertEq(amountFunded, amount);
        assertEq(fundme.getFunder(0), user);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(user);
        fundme.withdraw();
    }

    function testWithdrawalSuccess() public funded {
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundMeBalance = address(fundme).balance;

        vm.prank(msg.sender);
        fundme.withdraw();

        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundMeBalance = address(fundme).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders + startingFunderIndex; i++) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), starting_balance);
            fundme.fund{value: amount}();
        }

        uint256 startingFundMeBalance = address(fundme).balance;
        uint256 startingOwnerBalance = fundme.getOwner().balance;

        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        assert(address(fundme).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundme.getOwner().balance);
        assert((numberOfFunders + 1) * amount == fundme.getOwner().balance - startingOwnerBalance);
    }
}
