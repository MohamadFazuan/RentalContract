const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("RentalContract", function () {
    let RentalContract;
    let rentalContract;
    let owner;
    let renter;
    let addr2;

    beforeEach(async function () {
        [owner, renter, addr2] = await ethers.getSigners();
        RentalContract = await ethers.getContractFactory("RentalContract");
        rentalContract = await RentalContract.deploy("RentalNFT", "RNFT");
        await rentalContract.deployed();
        console.log("🚀 Contract deployed by:", owner.address);
    });

    describe("Property Management", function () {
        const tokenId = 1;
        const propertyDetails = {
            location: "123 Test St",
            numberOfRooms: 2,
            monthlyRent: ethers.utils.parseEther("1"),
            securityDeposit: ethers.utils.parseEther("2"),
            propertyType: "apartment",
            amenities: ["wifi", "parking"]
        };

        beforeEach(async function () {
            await rentalContract.mint(owner.address, tokenId);
            console.log("🏠 Minted property with token ID:", tokenId);
        });

        it("Should list a property correctly", async function () {
            await rentalContract.listProperty(
                tokenId,
                propertyDetails.location,
                propertyDetails.numberOfRooms,
                propertyDetails.monthlyRent,
                propertyDetails.securityDeposit,
                propertyDetails.propertyType,
                propertyDetails.amenities
            );
            console.log("📜 Property listed:", propertyDetails);

            const listed = await rentalContract.properties(tokenId);
            expect(listed.location).to.equal(propertyDetails.location);
            expect(listed.monthlyRent).to.equal(propertyDetails.monthlyRent);
        });

        it("Should not allow non-owners to list property", async function () {
            await expect(
                rentalContract.connect(addr2).listProperty(
                    tokenId,
                    propertyDetails.location,
                    propertyDetails.numberOfRooms,
                    propertyDetails.monthlyRent,
                    propertyDetails.securityDeposit,
                    propertyDetails.propertyType,
                    propertyDetails.amenities
                )
            ).to.be.revertedWith("Not owner");
        });
    });

    describe("User Management", function () {
        const tokenId = 1;
        const futureTime = Math.floor(Date.now() / 1000) + 86400; // 24 hours from now

        beforeEach(async function () {
            await rentalContract.mint(owner.address, tokenId);
            console.log("👤 Minted property for user management test with token ID:", tokenId);
        });

        it("Should set user correctly", async function () {
            await rentalContract.setUser(tokenId, renter.address, futureTime);
            console.log("✅ User set for token ID", tokenId, "with expiration time", futureTime);
            expect(await rentalContract.userOf(tokenId)).to.equal(renter.address);
        });

        it("Should return zero address for expired rental", async function () {
            const pastTime = Math.floor(Date.now() / 1000) - 86400;
            await rentalContract.setUser(tokenId, renter.address, pastTime);
            expect(await rentalContract.userOf(tokenId)).to.equal(ethers.constants.AddressZero);
        });
    });

    describe("Maintenance Requests", function () {
        const tokenId = 1;

        beforeEach(async function () {
            await rentalContract.mint(owner.address, tokenId);
            await rentalContract.setUser(tokenId, renter.address, Math.floor(Date.now() / 1000) + 86400);
            console.log("🛠 Maintenance setup done for token ID:", tokenId);
        });

        it("Should submit maintenance request", async function () {
            await rentalContract.connect(renter).submitMaintenanceRequest(tokenId, "Fix AC");
            const request = await rentalContract.maintenanceRequests(tokenId, 0);
            expect(request.description).to.equal("Fix AC");
            expect(request.isResolved).to.be.false;
            console.log("🔧 Maintenance request submitted for token ID", tokenId, "with description: Fix AC");
        });

        it("Should resolve maintenance request", async function () {
            await rentalContract.connect(renter).submitMaintenanceRequest(tokenId, "Fix AC");
            await rentalContract.resolveMaintenanceRequest(tokenId, 0);
            const request = await rentalContract.maintenanceRequests(tokenId, 0);
            expect(request.isResolved).to.be.true;
        });
    });

    describe("Security Deposits", function () {
        const tokenId = 1;
        const deposit = ethers.utils.parseEther("2");

        beforeEach(async function () {
            await rentalContract.mint(owner.address, tokenId);
            await rentalContract.listProperty(
                tokenId,
                "123 Test St",
                2,
                ethers.utils.parseEther("1"),
                deposit,
                "apartment",
                ["wifi"]
            );
            console.log("💰 Minted property for deposit test with token ID:", tokenId);
        });

        it("Should accept security deposit", async function () {
            await rentalContract.connect(renter).paySecurityDeposit(tokenId, { value: deposit });
            console.log("💵 Security deposit paid for token ID", tokenId, "with amount", deposit.toString());
            expect(await rentalContract.securityDeposits(tokenId)).to.equal(deposit);
        });

        it("Should return security deposit", async function () {
            await rentalContract.connect(renter).paySecurityDeposit(tokenId, { value: deposit });
            await rentalContract.setUser(tokenId, renter.address, Math.floor(Date.now() / 1000) + 86400);
            
            await expect(rentalContract.returnSecurityDeposit(tokenId))
                .to.changeEtherBalance(renter, deposit);
        });
    });
});