==================
DOCUMENTATION
To generate the documentation, follow the 2 steps hereunder :
1. Install 'jazzy' (https://github.com/realm/jazzy) or be sure it's already installed ('jazzy -- help' in a terminal).
2. Select and run the 'Documentation' scheme in Xcode (the script described in ‘Build phases’ provides the appropriate path).

You should see a new 'docs' folder inside which the selection of the 'index.html' file will display the complete documentation.


==================
TESTS (BDD)

Follow the steps below before launching the tests :
1. Create a WEBCOM namespace that will represent the place where implementations of the tests will be completed.
2. The namespace URL must be detailed in the 'ConstantsTests.swift' file thanks to the ‘WEBCOM.URL’ variable.
3. Four users must be registered in the namespace authentication part. Their mail and password must match the ones defined in the 'ConstantsTests.swift' file.
4. Generate an admin token on the authentication part of your namespace (bottom of the page).
5. In the ‘WebcomChatTests’ directory, create a ‘MySecretKey.plist’ file with {‘SecretKey’:YourAdminToken} as data. The file and key names must match what’s defined in the ‘ConstantsTests.swift’ file.  

Once done, select the appropriate target and the BDD tests should pass well with a simulator.


==================
APPLICATION (DEMO)

1. To be launched, this demo application needs to know :
	- Your phone number (may be false but it will be recorded as a key in the database).
	- The complete path of the namespace you have to create on the webcom server.
	- The provider name you use for your authentication (see the next point below).
These elements must be provided in the ‘Settings.bundle’ of the example application (can be changed later in your mobile settings once installed).
2. This application relies on the oAuth2 protocol to be authenticated on the webcom server (a simple tap on the first screen will launch the process).
However, if you have a valid token, you can use the appropriate method ‘authWith(…)’instead.
3. Once authenticated, your device contacts list should appear on the screen.
4. Select a contact who’s already registered on your webcom namespace to begin/continue a chat in a dedicated room.


==================
IMPORTANT POINTS

1. This API and all the provided tests rely on security rules described in the ‘SecurityRules.txt’ file.
Just copy paste them in the security part of your namespace.
2. Each method should have been tested but not the notifications (new messages, participant status...).
3. Remember that your application MUST be in charge of :
	- The MSISDN format (phone numbers are just ‘strings’ for the library).
	- Checking the URL namespace format (if equals to ‘’’’, a fatal error returns).
