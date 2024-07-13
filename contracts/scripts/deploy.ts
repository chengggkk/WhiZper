import { expect } from 'chai';
import {
    deployERC20ZKPVerifierToken,
    deployValidatorContracts,
    deployWhizperZKPVerifier,
    prepareInputs,
    publishState
} from './utils/deploy-utils';
import { packV2ValidatorParams, unpackV2ValidatorParams } from './utils/pack-utils';
import { Contract } from 'ethers';

const tenYears = 315360000;
const REQUEST_ID_SIG_VALIDATOR = 1;
const REQUEST_ID_MTP_VALIDATOR = 2;
const SIG_INPUTS = prepareInputs(
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    require('./common-data/valid_sig_user_non_genesis_challenge_address.json')
);
const MTP_INPUTS = prepareInputs(
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    require('./common-data/valid_mtp_user_non_genesis_challenge_address.json')
);


async function main() {
    let state: Contract, sig: Contract, mtp: Contract, token: Contract, whizper: Contract;

    async function setZKPRequests() {

        // #################### Set SIG V2 Validator ####################
        const query = {
            schema: BigInt('180410020913331409885634153623124536270'),
            claimPathKey: BigInt(
                '8566939875427719562376598811066985304309117528846759529734201066483458512800'
            ),
            operator: BigInt(1),
            slotIndex: BigInt(0),
            value: ['1420070400000000000', ...new Array(63).fill('0')].map((x) => BigInt(x)),
            circuitIds: ['credentialAtomicQuerySigV2OnChain'],
            queryHash: BigInt(
                '1496222740463292783938163206931059379817846775593932664024082849882751356658'
            ),
            claimPathNotExists: 0,
            metadata: 'test medatada',
            skipClaimRevocationCheck: false
        };

        await whizper.setZKPRequest(REQUEST_ID_SIG_VALIDATOR, {
            metadata: 'metadata',
            validator: await sig.getAddress(),
            data: packV2ValidatorParams(query)
        });


        // #################### Set MTP V2 Validator ####################
        // query.circuitIds = ['credentialAtomicQueryMTPV2OnChain'];
        // query.skipClaimRevocationCheck = true;

        // await token.setZKPRequest(REQUEST_ID_MTP_VALIDATOR, {
        //     metadata: 'metadata',
        //     validator: await mtp.getAddress(),
        //     data: packV2ValidatorParams(query)
        // });

    }

    async function erc20VerifierFlow(
        validator: 'SIG' | 'MTP'
    ): Promise<void> {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        await publishState(state, require('./common-data/user_state_transition.json'));
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        await publishState(state, require('./common-data/issuer_genesis_state.json'));

        const account = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

        let requestId, inputs, pi_a, pi_b, pi_c;
        if (validator === 'SIG') {
            requestId = await token.TRANSFER_REQUEST_ID_SIG_VALIDATOR();
            ({ inputs, pi_a, pi_b, pi_c } = SIG_INPUTS);
        } else {
            requestId = await token.TRANSFER_REQUEST_ID_MTP_VALIDATOR();
            ({ inputs, pi_a, pi_b, pi_c } = MTP_INPUTS);
        }

        await setZKPRequests();

        await token.submitZKPResponse(requestId, inputs, pi_a, pi_b, pi_c);
        expect(await token.isProofVerified(account, requestId)).to.be.true; // check proof is assigned
    }

    async function whizperVerifierFlow(
        validator: 'SIG' | 'MTP'
    ): Promise<void> {
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        await publishState(state, require('./common-data/user_state_transition.json'));
        // eslint-disable-next-line @typescript-eslint/no-var-requires
        await publishState(state, require('./common-data/issuer_genesis_state.json'));

        const account = '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266';

        let requestId, inputs, pi_a, pi_b, pi_c;
        if (validator === 'SIG') {
            requestId = await whizper.TRANSFER_REQUEST_ID_SIG_VALIDATOR();
            ({ inputs, pi_a, pi_b, pi_c } = SIG_INPUTS);
        } else {
            requestId = await whizper.TRANSFER_REQUEST_ID_MTP_VALIDATOR();
            ({ inputs, pi_a, pi_b, pi_c } = MTP_INPUTS);
        }

        await setZKPRequests();

        await whizper.createGroup(requestId, inputs, pi_a, pi_b, pi_c, 1, "hello");
        // await whizper.submitZKPResponse(requestId, inputs, pi_a, pi_b, pi_c, 1, 1, "222");
        // console.log(requestId, inputs, pi_a, pi_b, pi_c, 1, 1, "hello");
        // console.log(requestId, inputs, pi_a, pi_b, pi_c, 1, 1, "hello")
        // expect(await whizper.isProofVerified(account, requestId)).to.be.true; // check proof is assigned
    }


    try {

        const contractsSig = await deployValidatorContracts(
            'VerifierSigWrapper',
            'CredentialAtomicQuerySigV2Validator'
        );
        state = contractsSig.state;
        sig = contractsSig.validator;

        // const contractsMTP = await deployValidatorContracts(
        //     'VerifierMTPWrapper',
        //     'CredentialAtomicQueryMTPV2Validator',
        //     await state.getAddress()
        // );
        // mtp = contractsMTP.validator;

        // token = await deployERC20ZKPVerifierToken('zkpVerifier', 'ZKP');
        whizper = await deployWhizperZKPVerifier('WhiZper');

        await sig.setProofExpirationTimeout(tenYears);
        // await erc20VerifierFlow('SIG');
        await whizperVerifierFlow('SIG');
        // await mtp.setProofExpirationTimeout(tenYears);
        // await erc20VerifierFlow('MTP');
        // Get events from WhizperVerifier
        const events = await whizper.queryFilter(whizper.filters.Group());
        console.log(events);

        console.log("Request set");
    } catch (e) {
        console.log("error: ", e);
    }
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
