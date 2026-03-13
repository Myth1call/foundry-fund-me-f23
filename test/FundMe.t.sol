//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE=0.1 ether;
    uint256 constant STARTING_BALANCE=10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe=new DeployFundMe();
        fundMe=deployFundMe.run();
        vm.deal(USER,STARTING_BALANCE);
    }
    function testMinimumDollarIsFive() public view {
        console.log("fundMe.MINIMUM_USD(): %s", fundMe.MINIMUM_USD());
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }
    function testOwnerIsMsgSender() public view {
        console.log("fundMe.i_owner(): %s", fundMe.i_owner());
        assertEq(fundMe.getOwner(), msg.sender);
    }
    function testPriceFeedVersionIsCorrect() public view {
        console.log("fundMe.getVersion(): %s", fundMe.getVersion());
        assertEq(fundMe.getVersion(), 4);
    }
    function testFundFailsWithoutEnoughETH()public {
        vm.expectRevert();
        fundMe.fund();
    }
    function testFundUpdatesFundedDataStructure()public{
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded=fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);
    }
    function testAddsFunderToArrayOfFunders()public funded{
        address funder=fundMe.getFunder(0);
        assertEq(funder,USER);
    }
    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }
    function testOnlyOwnerCanWithdraw()public funded{
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }
    function testWithdrawWithSingleFunder()public funded{
        uint256 startingOwnerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance=address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        
        uint256 endingOwnerBalance=fundMe.getOwner().balance;
        uint256 endingFundMeBalance=address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance+startingOwnerBalance,endingOwnerBalance);
    }
    function testWithdrawFromMultipleFunders() public funded{
        uint160 numberOfFunders=10;
        uint160 startingFunderIndex=1;
        for(uint160 i=startingFunderIndex;i<numberOfFunders;i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }
        uint256 startingOwnerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance=address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();

        vm.stopPrank();
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
    }
    function testWithdrawFromMultipleFundersCheaper() public funded{
        uint160 numberOfFunders=10;
        uint160 startingFunderIndex=1;
        for(uint160 i=startingFunderIndex;i<numberOfFunders;i++){
            hoax(address(i),SEND_VALUE);
            fundMe.fund{value:SEND_VALUE}();
        }
        uint256 startingOwnerBalance=fundMe.getOwner().balance;
        uint256 startingFundMeBalance=address(fundMe).balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        vm.stopPrank();
        assert(address(fundMe).balance==0);
        assert(startingFundMeBalance+startingOwnerBalance==fundMe.getOwner().balance);
    }
}