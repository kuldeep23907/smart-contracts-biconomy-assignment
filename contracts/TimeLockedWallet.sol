// SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import "./interfaces/IERC20.sol";
import "./lib/ReentrancyGuard.sol";

contract TimeLockedWallet is ReentrancyGuard {
    bytes public constant EIP712_NAME = bytes("TimeLockedWallet");
    bytes public constant EIP712_REVISION = bytes("1");
    bytes32 internal constant EIP712_DOMAIN =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant CLAIM_TYPEHASH =
        keccak256("Claim(address token,uint256 amount,uint256 nonce)");
    bytes32 public DOMAIN_SEPARATOR;

    address public constant ETHER = address(0);
    struct LockedToken {
        uint256 amount;
        uint256 depositTimestamp;
        uint256 lockPeriod;
    }
    mapping(address => mapping(address => LockedToken)) lockedTokens;
    mapping(address => uint256) private nonces;

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,
                keccak256(EIP712_NAME),
                keccak256(EIP712_REVISION),
                block.chainid,
                address(this)
            )
        );
    }

    event Deposit(
        address indexed sender,
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    event Claim(
        address indexed receiver,
        address indexed token,
        uint256 amount
    );

    // deposit
    function deposit(
        address receiver,
        address token,
        uint256 amount,
        uint256 lockPeriod
    ) external payable nonReentrant {
        require(receiver != address(0), "TimeLockedWallet: invalid address");
        require(amount != 0, "TimeLockedWallet: invalid amount");
        require(lockPeriod > 0, "TimeLockedWallet: invalid lock period");

        LockedToken storage lockedToken = lockedTokens[receiver][token];

        if (token == address(ETHER)) {
            require(
                msg.value >= amount,
                "TimeLockedWallet: not sufficient ETH"
            );
            // in case depositor send more ETH, we need to transfer it back
            if (msg.value > amount) {
                (bool success, ) = msg.sender.call{value: msg.value - amount}(
                    ""
                );
                require(success, "TimeLockedWallet: transfer failed");
            }
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }
        lockedToken.amount += amount;
        lockedToken.depositTimestamp = block.timestamp;
        lockedToken.lockPeriod = lockPeriod;

        emit Deposit(msg.sender, receiver, token, amount);
    }

    // claim
    function claim(
        address receiver,
        address token,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external nonReentrant {
        require(
            verify(receiver, token, amount, r, s, v),
            "TimeLockedWallet: invalid signature"
        );
        nonces[receiver]++;

        LockedToken storage lockedToken = lockedTokens[receiver][token];
        require(
            lockedToken.amount >= amount,
            "TimeLockedWallet: not enough balance"
        );
        require(
            block.timestamp >=
                lockedToken.depositTimestamp + lockedToken.lockPeriod,
            "TimeLockedWallet: tokens locked"
        );

        lockedToken.amount -= amount;
        if (token == address(ETHER)) {
            require(
                address(this).balance >= amount,
                "TimeLockedWallet: Not enough ETH"
            );
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "TimeLockedWallet: transfer failed");
        } else {
            require(
                IERC20(token).balanceOf(address(this)) >= amount,
                "TimeLockedWallet: Not enough tokens"
            );
            IERC20(token).transfer(receiver, amount);
        }

        emit Claim(receiver, token, amount);
    }

    function verify(
        address receiver,
        address token,
        uint256 amount,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) internal view returns (bool) {
        bytes32 structHash = keccak256(
            abi.encode(CLAIM_TYPEHASH, token, amount, nonces[receiver])
        );
        bytes32 signingHash = keccak256(
            abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash)
        );
        address signer = ecrecover(signingHash, v, r, s);
        require(signer != address(0), "Invalid signature");
        return signer == receiver;
    }

    // checkBalance
    function getLockedTokenDetails(address receiver, address token)
        public
        view
        returns (LockedToken memory)
    {
        return lockedTokens[receiver][token];
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }
}
