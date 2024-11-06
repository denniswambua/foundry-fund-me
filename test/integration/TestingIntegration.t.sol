// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test} from "forge-std/Test.sol";

import {FundMe} from "../../src/FundMe.sol";

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

contract TestIntegration is Test {
    FundMe fundme;
    address user = makeAddr("Alice");
    uint256 amount = 0.1 ether;
    uint256 starting_balance = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(user, starting_balance);
    }

    function testUserCanFundInteractions() public {
        FundFundMe fundFundMe = new FundFundMe();
        fundFundMe.fundFundMe(address(fundme));

        WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
        withdrawFundMe.withdrawFundMe(address(fundme));

        assertEq(address(fundme).balance, 0);
        
    }
}
