// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";
import {FundMe} from "../../src/FundMe.sol";
import {Test, console} from "forge-std/Test.sol";

contract InteractionsTest is Test {
    FundMe public fundMe;
    DeployFundMe deployFundMe;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;

    address Karina = makeAddr("Karina");


    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(Karina, STARTING_USER_BALANCE);
    }

    function testUserCanFundAndOwnerWithdraw() public {
    vm.txGasPrice(0);

    uint256 preUserBalance = Karina.balance;
    uint256 preOwnerBalance = fundMe.getOwner().balance;
    uint256 preFundMeBalance = address(fundMe).balance;

    vm.prank(Karina);
    fundMe.fund{value: SEND_VALUE}();

    vm.prank(fundMe.getOwner());
    fundMe.withdraw();

    uint256 afterUserBalance = Karina.balance;
    uint256 afterOwnerBalance = fundMe.getOwner().balance;

    assertEq(address(fundMe).balance, 0);
    assertEq(afterUserBalance + SEND_VALUE, preUserBalance);
    assertEq(afterOwnerBalance, preOwnerBalance + preFundMeBalance + SEND_VALUE);
}
}