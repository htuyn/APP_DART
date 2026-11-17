const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("AchievementCertificate", function () {
  let certificate;
  let issuer;
  let recipient;
  let stranger;

  const id = (value) => ethers.id(value);
  const ACHIEVEMENT = 1;
  const COURSE = 2;

  beforeEach(async function () {
    [issuer, recipient, stranger] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("AchievementCertificate", issuer);
    certificate = await Factory.deploy();
    await certificate.waitForDeployment();
  });

  for (const [type, label] of [[ACHIEVEMENT, "achievement"], [COURSE, "course completion"]]) {
    it(`issues a ${label} certificate`, async function () {
      const certificateId = id(`${label}-id`);
      const achievementHash = id(`${label}-hash`);

      await expect(
        certificate.issueCertificate(certificateId, type, recipient.address, achievementHash),
      )
        .to.emit(certificate, "CertificateIssued")
        .withArgs(
          certificateId,
          type,
          recipient.address,
          achievementHash,
          (await ethers.provider.getBlock("latest")).timestamp + 1,
        );

      const [record, valid] = await certificate.verifyCertificate(certificateId);
      expect(record.certificateId).to.equal(certificateId);
      expect(record.certificateType).to.equal(type);
      expect(record.recipient).to.equal(recipient.address);
      expect(record.achievementHash).to.equal(achievementHash);
      expect(record.issuedAt).to.be.greaterThan(0);
      expect(record.revoked).to.equal(false);
      expect(valid).to.equal(true);
    });
  }

  it("rejects issueCertificate from a non-issuer", async function () {
    await expect(
      certificate.connect(stranger).issueCertificate(
        id("stranger-id"),
        ACHIEVEMENT,
        recipient.address,
        id("stranger-hash"),
      ),
    ).to.be.revertedWithCustomError(certificate, "OnlyIssuer");
  });

  it("rejects a duplicate achievement hash", async function () {
    const hash = id("shared-hash");
    await certificate.issueCertificate(id("first-id"), ACHIEVEMENT, recipient.address, hash);
    await expect(
      certificate.issueCertificate(id("second-id"), COURSE, recipient.address, hash),
    ).to.be.revertedWithCustomError(certificate, "DuplicateAchievementHash");
  });

  it("rejects a duplicate certificate id", async function () {
    const certificateId = id("shared-id");
    await certificate.issueCertificate(certificateId, ACHIEVEMENT, recipient.address, id("hash-a"));
    await expect(
      certificate.issueCertificate(certificateId, COURSE, recipient.address, id("hash-b")),
    ).to.be.revertedWithCustomError(certificate, "DuplicateCertificateId");
  });

  it("revokes a certificate and reports it as invalid", async function () {
    const certificateId = id("revoke-id");
    await certificate.issueCertificate(certificateId, COURSE, recipient.address, id("revoke-hash"));

    await expect(certificate.revokeCertificate(certificateId))
      .to.emit(certificate, "CertificateRevoked")
      .withArgs(certificateId, issuer.address);

    const [record, valid] = await certificate.verifyCertificate(certificateId);
    expect(record.revoked).to.equal(true);
    expect(valid).to.equal(false);
  });
});
