import { ethers, upgrades } from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { deployClaimBuilder, deployIdentityLib } from '../utils/deploy-utils';

export class OnchainIdentityDeployHelper {
  constructor(
    private signers: SignerWithAddress[],
    private readonly enableLogging: boolean = false
  ) {}

  static async initialize(
    signers: SignerWithAddress[] | null = null,
    enableLogging = false
  ): Promise<OnchainIdentityDeployHelper> {
    let sgrs;
    if (signers === null) {
      sgrs = await ethers.getSigners();
    } else {
      sgrs = signers;
    }
    return new OnchainIdentityDeployHelper(sgrs, enableLogging);
  }

  async deployIdentity(
    stateAddress: string,
    smtLibAddress: string,
    poseidon3Address: string,
    poseidon4Address: string
  ): Promise<{
    identity: Contract;
  }> {
    const owner = this.signers[0];

    this.log('======== Identity: deploy started ========');

    // const cb = await deployClaimBuilder();
    const cbAddress = "0xc08ba98f52ae838f61db664fe10ee24719969a76"
    // const il = await deployIdentityLib(
    //   smtLibAddress,
    //   poseidon3Address,
    //   poseidon4Address
    // );
    const ilAddress = "0x0036abee4fe5a36a7f34eeedc5b2f963b3a013d4"

    this.log('deploying Identity...');
    const IdentityFactory = await ethers.getContractFactory('IdentityExample', {
      libraries: {
        ClaimBuilder: cbAddress,
        IdentityLib: ilAddress,
      }
    });
    const Identity = await upgrades.deployProxy(IdentityFactory, [stateAddress], {
      unsafeAllowLinkedLibraries: true
    });
    await Identity.waitForDeployment();
    this.log(
      `Identity contract deployed to address ${await Identity.getAddress()} from ${await owner.getAddress()}`
    );

    this.log('======== Identity: deploy completed ========');

    return {
      identity: Identity
    };
  }

  private log(...args): void {
    this.enableLogging && console.log(args);
  }
}
