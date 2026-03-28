// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //us -> fundeMeTest -> FundMe
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() external view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        console.log("Owner address:", fundMe.i_owner());
        console.log("Test contract address:", address(this));
        assertEq(fundMe.i_owner(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 我们可以如何处理系统外的地址？

    // 1. Unit Testing
    // 测试我们代码的某个具体功能（单元测试）
    // Testing a specific part of our code

    // 2. Integration Testing
    // 测试我们代码的不同模块能否协同工作（集成测试）
    // our code works with other parts of our code

    // 3. Forked Testing
    // 在模拟的真实环境中测试代码（分叉测试）
    // Testing our code on a simulated real environment

    // 4. Staging
    // 在真实环境中测试，但不是生产环境（预发布环境测试）
    // Testing our code in a real environment that is not prod

    //unit test
    function testPriceFeedVersionIsAccurate() public view {
        console.log("Price feed version:", fundMe.getVersion());
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey,the next line of code should revert
        //assert(This tx fails/reverts);

        fundMe.fund{value: 0.001 ether}();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //the next tx will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.s_addressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.s_funders(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        //arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        uint256 gasStart = gasleft(); //gasleft()solidity内置函数，返回当前剩余的gas量
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw(); //should have spent gas?
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used:", gasUsed);

        //assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //Foundry 允许你用一个 uint160 转成 address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            fundMe.getOwner().balance
        );
    }

    function testWithdrawFromMultipleFundersCheaper() public funded {
        //arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            hoax(address(i), SEND_VALUE); //Foundry 允许你用一个 uint160 转成 address
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        //assert
        assertEq(address(fundMe).balance, 0);
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            fundMe.getOwner().balance
        );
    }
}

//us -> fundeMeTest -> FundMe
//modular testing
//modular deployment
