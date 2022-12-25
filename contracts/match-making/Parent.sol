// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// import "./WifeToBe.sol";
// import "./HusbandToBe.sol";
import "./interfaces/IParent.sol";
import "./interfaces/IWifeToBe.sol";
import "./interfaces/IHusbandToBe.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/** Think of this as a metaverse of people of real world scenario where 
 * technology could be made to govern human activities. Acceptance by usage 
 * auto-absorbs and validate its existence.
 *  - Humans are facing so much uncertainty today because of unwillingness to 
 *    portray the right habit.
 *  - We could have our world and feelings built into virtual reality so we
 *    don't have to depend on others to make decisions. And since "trust" is
 *    difficult to achieve, let's have the mindless do the job so we can trust less.
 * 
 */
contract Parent is IParent, Ownable, Pausable {
    IBank private bank;

    // Asset
    IERC20 private asset;

    // Price to pay for asking daughter hand in marriage
    uint private bridePrice;

    bool private initialized;

    // Daughters
    mapping(address => Daughter) public daughters;

    // Parents' approval to pay brideprice
    mapping(address => bool) public paymentApprovals;

    // Only daughters can call
    modifier onlyDaughter(address who) {
        require(daughters[who].isOurDaughter, "Not related");
        _;
    }

    modifier isInitialized() {
        require(initialized, "contract not initialized");
        _;
    }

    // At construction, we assume the parent contract owns "n" number of daughters
    constructor(IBank _bank, uint _brideprice) {
        bridePrice = _brideprice;
        if (address(_bank) == address(0)) revert InvalidBankAddress();
        initialized = false;
    }

    receive() external payable {
        require(msg.value > 0);
    }

    function initialize(IWifeToBe[] memory _daughters) public onlyOwner {
        require(!initialized, "already initialized");
        initialized = true;
        for (uint i = 0; i < _daughters.length; i++) {
            IWifeToBe newDaughter = _daughters[i];
            require(
                address(newDaughter) != address(0),
                "InvalidDaughter referenced"
            );
            require(IWifeToBe(newDaughter).setParent(IParent(address(this))));
            daughters[address(newDaughter)].isOurDaughter = true;
        }
    }

    function getMarriageApproval(
        IWifeToBe _daughter
    )
        external
        whenNotPaused
        isInitialized
        onlyDaughter(address(_daughter))
        returns (bool _return)
    {
        uint _brideprice = IERC20(_getAsset()).allowance(
            _msgSender(),
            address(this)
        );
        if (!paymentApprovals[_msgSender()])
            revert NotApprovedForPricePayment(_msgSender());
        if (_brideprice < bridePrice) revert InsufficientBridePrice();
        if (
            IERC20(_getAsset()).transferFrom(
                _msgSender(),
                address(this),
                _brideprice
            )
        ) {
            address daughter = address(_daughter);
            daughters[daughter].marriedTo = IHusbandToBe(msg.sender);
            daughters[daughter].bridePrice = _brideprice;
            require(
                IWifeToBe(_daughter).setMarriageStatus(IHusbandToBe(payable(_msgSender()))),
                "Failed"
            );
            _return = true;
        }

        return _return;
    }

    function approveToPayBridePrice(
        IHusbandToBe proposer,
        IWifeToBe proposedTo
    ) public onlyOwner isInitialized{
        address _husband = address(proposer);
        if (daughters[address(proposedTo)].pricePaymentApproved)
            revert ApprovalAlreadyGivenToSomeone();
        if (paymentApprovals[_husband])
            revert ProposerAlreadyApproved(_husband);
        paymentApprovals[_husband] = true;
    }

    function adjustBridePrice(uint newBridePrice) public onlyOwner {
        bridePrice = newBridePrice;
    }

    function getBridePrize() external view returns (uint) {
        return _getBridePrice();
    }

    function spendMoney(address to, uint amount) public onlyOwner isInitialized {
        require(IERC20(_getAsset()).transfer(to, amount), "Failed");
    }

    function _getAsset() internal view returns (IERC20 _asset) {
        _asset = asset;
    }

    function _getBridePrice() internal view returns (uint _price) {
        _price = bridePrice;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function getEligibility() external view override returns (bool) {}

}