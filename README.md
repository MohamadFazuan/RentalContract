# 🏠 RentalContract - ERC721 Rental System

## 📜 Contract Summary

### **Overview**
The `RentalContract` is an ERC-721-based smart contract that allows property owners to tokenize real estate as NFTs. It includes functionalities for listing properties, renting them out, handling maintenance requests, and managing security deposits.

### **Key Features**
- **Minting NFTs**: Owners can mint new properties as NFTs.
- **Listing Properties**: Owners can list their properties with rent and deposit details.
- **Tenant Management**: Tenants can be assigned to properties with an expiration date.
- **Maintenance Requests**: Tenants can submit maintenance requests.
- **Security Deposits**: Tenants can pay and retrieve security deposits.

# 🛠 Testing the Contract with Hardhat

## 1️⃣ Install Dependencies

Make sure you have Hardhat installed:
```
npm install --save-dev hardhat chai ethers
npx run test test/RentalContract.test.js
```

### Feel free to contribute and comment ! 🎉