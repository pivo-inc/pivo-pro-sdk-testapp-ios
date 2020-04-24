typedef unsigned long ul;

/**
	Returns a radomly generated 4 bytes inquiry value;
*/
ul getRandomInquiry(void);


/**
	Returns authentication code for input value

	@input	input code

	@return	authentication code
*/
ul getAuthAnswer(ul input);

/**
	Verify wether input and answer is matched or not

	@input	input code
	@answer	the value for verifying authentication

	@return	1 : succes, 0 : fail
*/
bool verifyAuthCode(ul input, ul answer);
