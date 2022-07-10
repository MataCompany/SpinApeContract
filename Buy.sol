//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./Ref.sol";

contract SpinApeBuy is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public usdtToken;
    IERC20 public spinApe;
    SpinApeRef public RefContract;

    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public constant DAYS_IN_MONTH = 30;

    mapping(address => uint256) public totalBuy;
    mapping(address => uint256) public claimed;

    struct BuyType {
        uint256 tge; // 10% -> 1000
        uint256 lockedTimeInDays; // 6 months = 180 days
        uint256 monthlyUnlockRate; // 3,75% = 375
        uint256 vestingDays; // 24 months = 720 days
    }

    BuyType public buyType;
    uint256 public startClaim;

    address private fundAddress;
    address[] public winnerSeed;
    address private refAddress;

    uint256 public rate;
    uint256 public totalToken;
    uint256 public totalTokenSaled;
    uint256 public startDate;
    uint256 public endDate;
    uint256 public countBuy;

    bool public statusSale;
    bool public initializeStatus;

    event SetBuyType(
        uint256 tge,
        uint256 lockedTimeInDays,
        uint256 monthlyUnlockRate,
        uint256 vestingMonth
    );

    event Harvest(address user, uint256 amount);

    // Init
    function initialize(
        address _USD,
        address _spinApe,
        address _FundAddress,
        address _RefAddress,
        uint256 _Rate,
        uint256 _StartDate,
        uint256 _startClaim,
        uint256 _EndDate,
        uint256 _TotalTokenSale,
        bool _Status
    ) public onlyOwner {
        require(initializeStatus == false, "Already initialized");

        initializeStatus = true;

        usdtToken = IERC20(_USD);
        spinApe = IERC20(_spinApe);
        RefContract = SpinApeRef(_RefAddress);
        refAddress = _RefAddress;
        fundAddress = _FundAddress;
        rate = _Rate;
        startDate = _StartDate;
        startClaim = _startClaim;
        endDate = _EndDate;
        statusSale = _Status;
        totalToken = _TotalTokenSale;
    }

    function setBuyType(
        uint256 tge,
        uint256 lockedTimeInDays,
        uint256 monthlyUnlockRate,
        uint256 vestingMonth
    ) public onlyOwner {
        // check if buy is set
        require(
            buyType.lockedTimeInDays == 0 &&
                buyType.monthlyUnlockRate == 0 &&
                buyType.tge == 0 &&
                buyType.vestingDays == 0,
            "Already set"
        );

        buyType = BuyType(
            tge,
            lockedTimeInDays,
            monthlyUnlockRate,
            vestingMonth
        );

        emit SetBuyType(tge, lockedTimeInDays, monthlyUnlockRate, vestingMonth);
    }

    function buy(uint256 amount, address refBy) public nonReentrant {
        require(amount >= 200 ether,"Error: Minimum allocation is 200");
        require(
            usdtToken.balanceOf(msg.sender) >= amount,
            "Error: Invalid balance of USD"
        );
        require(
            totalTokenSaled + amount <= totalToken,
            "Error: Invalid balance of Token"
        );
        require(statusSale == true, "Error: Invalid time");
        require(
            startDate <= block.timestamp && endDate >= block.timestamp,
            "Error: Invalid Time"
        );
        uint256 totalUsdNeed = RefContract.calculateFundRef(msg.sender, amount, refBy);
        usdtToken.safeTransferFrom(msg.sender, fundAddress, amount - totalUsdNeed);
        usdtToken.safeTransferFrom(msg.sender, refAddress, totalUsdNeed);
        totalBuy[msg.sender] += amount * rate;
        totalTokenSaled += amount;
        countBuy++;
    }

    function harvest() public {
        uint256 getAmount = getTge(msg.sender, block.timestamp);

        spinApe.safeTransfer(msg.sender, getAmount);

        claimed[msg.sender] += getAmount;

        emit Harvest(msg.sender, getAmount);
    }

    function getTge(address _user, uint256 _toTimeStamp)
        public
        view
        returns (uint256)
    {
        uint256 totalReward;

        if (
            _toTimeStamp >
            startClaim + buyType.lockedTimeInDays * SECONDS_IN_DAY
        ) {
            uint256 totalMonthPassed = (_toTimeStamp -
                startClaim -
                buyType.lockedTimeInDays *
                SECONDS_IN_DAY) / (SECONDS_IN_DAY * DAYS_IN_MONTH);

            totalMonthPassed = totalMonthPassed >
                (buyType.vestingDays) / DAYS_IN_MONTH
                ? buyType.vestingDays / DAYS_IN_MONTH
                : totalMonthPassed;

            totalReward += ((totalBuy[_user] *
                (buyType.monthlyUnlockRate * totalMonthPassed + buyType.tge)) /
                10000);
        } else if (_toTimeStamp > startClaim) {
            totalReward += (totalBuy[_user] * buyType.tge) / 10000;
        }

        return totalReward - claimed[_user];
    }

    function getTotalToken() public view returns (uint256) {
        return totalToken;
    }

    function getTotalTokenSale() public view returns (uint256) {
        return totalTokenSaled;
    }

    function getRate() public view returns (uint256) {
        return rate;
    }

    function getTotalOfUser(address _user) public view returns (uint256) {
        return totalBuy[_user];
    }

    function getStartDate() public view returns (uint256) {
        return startDate;
    }

    function getEndDate() public view returns (uint256) {
        return endDate;
    }

    function getCountBuy() public view returns (uint256) {
        return countBuy;
    }
}
