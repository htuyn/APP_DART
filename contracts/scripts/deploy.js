const hre = require("hardhat");

async function main() {
  const Certificate = await hre.ethers.getContractFactory("AchievementCertificate");
  const certificate = await Certificate.deploy();
  await certificate.waitForDeployment();

  console.log("AchievementCertificate deployed to:", await certificate.getAddress());
  console.log("Issuer:", await certificate.issuer());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
