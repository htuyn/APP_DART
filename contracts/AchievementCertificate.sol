// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract AchievementCertificate {
    uint8 public constant ACHIEVEMENT_CERTIFICATE = 1;
    uint8 public constant COURSE_COMPLETION_CERTIFICATE = 2;

    struct Certificate {
        bytes32 certificateId;
        uint8 certificateType;
        address recipient;
        bytes32 achievementHash;
        uint256 issuedAt;
        bool revoked;
    }

    address public immutable issuer;
    mapping(bytes32 => Certificate) private certificates;
    mapping(bytes32 => bool) public certificateIdExists;
    mapping(bytes32 => bool) public achievementHashExists;

    event CertificateIssued(
        bytes32 indexed certificateId,
        uint8 indexed certificateType,
        address indexed recipient,
        bytes32 achievementHash,
        uint256 issuedAt
    );
    event CertificateRevoked(bytes32 indexed certificateId, address indexed issuer);

    error OnlyIssuer();
    error InvalidCertificateId();
    error InvalidCertificateType();
    error InvalidRecipient();
    error InvalidAchievementHash();
    error DuplicateCertificateId();
    error DuplicateAchievementHash();
    error CertificateNotFound();

    modifier onlyIssuer() {
        if (msg.sender != issuer) revert OnlyIssuer();
        _;
    }

    constructor() {
        issuer = msg.sender;
    }

    function issueCertificate(
        bytes32 certificateId,
        uint8 certificateType,
        address recipient,
        bytes32 achievementHash
    ) external onlyIssuer {
        if (certificateId == bytes32(0)) revert InvalidCertificateId();
        if (
            certificateType != ACHIEVEMENT_CERTIFICATE &&
            certificateType != COURSE_COMPLETION_CERTIFICATE
        ) revert InvalidCertificateType();
        if (recipient == address(0)) revert InvalidRecipient();
        if (achievementHash == bytes32(0)) revert InvalidAchievementHash();
        if (certificateIdExists[certificateId]) revert DuplicateCertificateId();
        if (achievementHashExists[achievementHash]) revert DuplicateAchievementHash();

        uint256 issuedAt = block.timestamp;
        certificates[certificateId] = Certificate({
            certificateId: certificateId,
            certificateType: certificateType,
            recipient: recipient,
            achievementHash: achievementHash,
            issuedAt: issuedAt,
            revoked: false
        });
        certificateIdExists[certificateId] = true;
        achievementHashExists[achievementHash] = true;

        emit CertificateIssued(
            certificateId,
            certificateType,
            recipient,
            achievementHash,
            issuedAt
        );
    }

    function revokeCertificate(bytes32 certificateId) external onlyIssuer {
        if (!certificateIdExists[certificateId]) revert CertificateNotFound();
        Certificate storage certificate = certificates[certificateId];
        if (!certificate.revoked) {
            certificate.revoked = true;
            emit CertificateRevoked(certificateId, msg.sender);
        }
    }

    function verifyCertificate(bytes32 certificateId)
        external
        view
        returns (Certificate memory certificate, bool valid)
    {
        if (!certificateIdExists[certificateId]) {
            return (certificates[certificateId], false);
        }
        certificate = certificates[certificateId];
        valid = !certificate.revoked;
    }
}
