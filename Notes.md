## Parameters 

The parameters mentioned (like s_subscriptionId, keyHash, callbackGasLimit, requestConfirmations, and numWords) are essential for calling the requestRandomWords() function when interacting with the Chainlink VRF system. These parameters dictate how the randomness request will be processed, including how much gas you’re willing to use, how secure the randomness should be (through confirmations), and how many random numbers you need.

## uint256 s_subscriptionId:

This is the subscription ID that the contract will use for funding the randomness requests.
You must have a subscription set up on the Chainlink VRF platform. This subscription is a pool of funds used to pay for the VRF services.

## bytes32 keyHash:

This is the gas lane key hash value, which indicates the maximum gas price (in wei) that you are willing to pay for the VRF request.
The keyHash also functions as an identifier for the specific Chainlink VRF job (i.e., which off-chain node will process the randomness request).
By adjusting this value, you can control how much gas you're willing to pay, depending on network congestion and other factors.

## uint32 callbackGasLimit:

This defines the amount of gas that will be used for the callback request, specifically when the Chainlink node calls your fulfillRandomWords() function.
The callbackGasLimit must be less than the maxGasLimit on the VRF Coordinator contract.
If the limit is too low, the fulfillRandomWords() function might fail, but the subscription will still be charged for the request, so you need to set this carefully based on how complex the callback logic is.

## uint16 requestConfirmations:

This specifies how many block confirmations the Chainlink node should wait before processing the request.
More confirmations result in greater security, as it reduces the risk of certain attacks (e.g., block reorganization).
It must be greater than the minimum confirmations required by the coordinator contract.

## uint32 numWords:

This determines how many random words (random numbers) are returned in the response.
You can request multiple random numbers in one request to reduce gas costs, especially if you need more than one random value for your use case.
The complexity and cost of processing these values will depend on your implementation of fulfillRandomWords(), so you might need to adjust the gas limit.



## Functions

## requestRandomWords(bool enableNativePayment):

This function sends a randomness request to the Chainlink VRF Coordinator using the previously specified parameters.
The enableNativePayment parameter allows you to choose whether to pay for the request in native blockchain tokens (e.g., ETH) or LINK tokens:
enableNativePayment = true: Pay in native tokens.
enableNativePayment = false: Pay in LINK tokens.
Depending on the use case and available funds, you can toggle between these two payment options.

## fulfillRandomWords():

This is the callback function that receives the random values from Chainlink VRF once they are ready.
Chainlink VRF will call this function with the requested random numbers, and it's the developer's responsibility to process or store these values within the contract.
This function needs to be optimized for gas usage, especially when multiple random numbers are requested.

## getRequestStatus():

This function retrieves details about a VRF request, given a specific request ID.
It can be used to check the status of a request, such as whether it has been fulfilled or is still pending.
