// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import './ERC4907.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract RentalContract is ERC4907, Ownable {
    address tenant;
    address payable landlord;
    uint256 depositPrice;
    uint256 rentalPrice;
    uint256 paymentDate;
    bytes32 agreementHash;

    struct Rent {
        address payable _landlord;
        uint256 _amount;
        uint64 _expires;
        uint256 tokenId;
    }

    struct Agreement {
        bytes32 _agreementID;
        address payable _landlord;
        address _tenant;
        uint256 _deposit;
        uint64 expires;
        bool rented;
        bytes32 assets;
    }

    modifier onlyTenant() {
        require(msg.sender == tenant, "This is for tenant only!");
        _;
    }

    modifier onlyLandlord() {
        require(msg.sender == landlord, "This is for landlord only!");
        _;
    }

    constructor(string memory name_, string memory symbol_)
        ERC4907(name_, symbol_)
    {}

    function mint(uint256 tokenId, address to) public onlyLandlord{
        _mint(to, tokenId);
    }

    event PaymentReceived(Rent _rental);

    //agreement declined
    function cancelAgreement(Agreement memory _agreement) public onlyLandlord {
        // occupied false, deposit transafer to msg.sender

        _agreement.rented == false;

    }

    function rentPay(Rent memory _rental, uint256 _amount) public onlyTenant{

        _rental._landlord.transfer(_amount);
        
        // emit PaymentReceived(Rent _rental memory);
    }

    /* 1. Unlock MetaMask account
    ethereum.enable()
    */

    /* 2. Get message hash to sign
    getMessageHash(
        0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C,
        123,
        "coffee and donuts",
        1
    )

    hash = "0xcf36ac4f97dc10d91fc2cbb20d718e94a8cbfe0f82eaedc6a4aa38946fb797cd"
    */
    function getMessageHash(
        address _to,
        uint256 _amount,
        bytes32 _agreementHash,
        string memory _message,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(_to, _amount, _agreementHash, _message, _nonce)
            );
    }

    /* 3. Sign message hash
    # using browser
    account = "copy paste account of signer here"
    ethereum.request({ method: "personal_sign", params: [account, hash]}).then(console.log)

    # using web3
    web3.personal.sign(hash, web3.eth.defaultAccount, console.log)

    Signature will be different for different accounts
    0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function getEthSignedMessageHash(bytes32 _messageHash)
        public
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /* 4. Verify signature
    signer = 0xB273216C05A8c0D4F0a4Dd0d7Bae1D2EfFE636dd
    to = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C
    amount = 123
    message = "coffee and donuts"
    nonce = 1
    signature =
        0x993dab3dd91f5c6dc28e17439be475478f5635c92a56e17e82349d3fb2f166196f466c0b4e0c146f285204f0dcb13e5ae67bc33f4b888ec32dfe0a063e8f3f781b
    */
    function verify(
        address _signer,
        address _to,
        uint256 _amount,
        bytes32 _agreementHash,
        string memory _message,
        uint256 _nonce,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(
            _to,
            _amount,
            _agreementHash,
            _message,
            _nonce
        );
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        public
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function time() public view returns(uint256){
        return block.timestamp;
    }
}
