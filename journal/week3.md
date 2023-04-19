# Week 3 — Decentralized Authentication
- Authentication is the process of verifying the identity of a user or system to ensure they have the necessary permissions to access a resource. It involves verifying the user's credentials such as username and password or using other methods such as multi-factor authentication (MFA) like OTPs or biometrics.

- Decentralized authentication is a way of distributing the authentication process across multiple systems and services rather than relying on a single central authority. This approach is often used in systems that involve multiple parties, such as blockchain networks or decentralized applications (dApps).

- Decentralized authentication is important because it increases security by reducing the risk of a single point of failure. It also allows users to have more control over their own data and privacy, as they can choose which authentication providers they trust and grant access to their data.

- Amazon Cognito is a service that provides user sign-up, sign-in, and access control for web and mobile applications. It supports decentralized authentication by allowing users to sign in using their existing social media or identity providers, such as Facebook, Google, or Amazon, and by allowing developers to create their own custom authentication providers. Developers can integrate Cognito into their applications using the provided SDKs and APIs.


## Getting Through The Code
- Enter the Cognito page in AWS, and create a user pool. We are interested in a user pool for now.
- Let users sign in with email only and username ( no username options)
- Set a password policy, default Cognito is good. Set up no MFA.
- Enable self-service account recovery (for user to recover their accounts) and set the delivery method to "email" (free tier covers SES )
- Configure self-service sign-up; enable self-registration (technically do not need this as we are not going to be using the Cognito hosted UI, but keep in check otherwise)
- In attribute verification, allow Cognito-assisted verification and confirmation. Send email only. Enable "keep original attribute value when an update is pending". Select email.
- Select some required attributes; "name" and "preferred username" is what is needed for now. Cognito allows the user to store data in it but andrew prefers to store that data in own database as records.
- Configure message delivery to use email delivery by Cognito (temporarily). Amazon SES will be configured later. set the default "FROM email address". do not set any for the "REPLY-TO".
- Integrating the app. Select a friendly name for app (cruddur-user-pool); do not use the Cognito UI; use a public app client AS THE APP TYPE; set app name (cruddur); do not generate a client secret.
- review and Create the user pool.

```
A callback URL is a URL that is provided by a web application to redirect the user's browser back to the application after the user completes an action, such as logging in with a third-party authentication provider or making a payment with a payment gateway.

The callback URL is often used as part of an OAuth or OpenID Connect authentication flow, where the user is redirected to the authentication provider's website to log in, and then back to the original web application with an authorization token. The callback URL is where the authentication provider sends the authorization token after the user has successfully logged in.

In the case of a payment gateway, the callback URL is used to redirect the user back to the web application after the payment has been completed, along with information about the transaction such as the transaction ID and status.

Some common use cases for callback URLs include:

-   OAuth and OpenID Connect authentication flows
-   Payment processing with payment gateways
-   Social media integrations, such as sharing content or posting updates
-   Webhooks and event-driven architectures, where an external service needs to notify the web application about an event that has occurred.
```

- in order to use Cognito in our app, we need to use AWS Amplify.
```
AWS Amplify is a development platform provided by Amazon Web Services (AWS) that makes it easier to build cloud-powered web and mobile applications. It provides developers with a set of pre-built UI components, libraries, and tools to quickly build, deploy, and manage their applications on AWS.

Amplify is particularly useful for developers who want to build modern web and mobile applications using popular frameworks such as React, Vue, Angular, and others. It offers a variety of features, including authentication, storage, APIs, analytics, and more, all of which can be easily integrated into your applications with just a few lines of code.

In summary, AWS Amplify is used to simplify and accelerate the development of cloud-powered applications by providing developers with pre-built UI components, libraries, and tools. It helps developers to quickly build and deploy their applications on AWS, and offers a wide range of features that can be easily integrated into their applications.
```

- Go into the code, go to the `frontend-react-js` and run `npm install aws-amplify --save` to save it as a dependency we need to use
```Shell
npm install aws-amplify --save
```
- Get into the `App.js` file in the `frontend-react-js` dir and paste the following in;
	- `REACT_APP` is the way the react application identifies and uses env-vars.
	- we are not going to use the Cognito Identity Pool so delete that.
```Node
import { Amplify } from 'aws-amplify';

Amplify.configure({
  "AWS_PROJECT_REGION": process.env.REACT_APP_AWS_PROJECT_REGION,
  "aws_cognito_region": process.env.REACT_APP_AWS_COGNITO_REGION,
  "aws_user_pools_id": process.env.REACT_APP_AWS_USER_POOLS_ID,
  "aws_user_pools_web_client_id": process.env.REACT_APP_CLIENT_ID,
  "oauth": {},
  Auth: {
    // We are not using an Identity Pool
    // identityPoolId: process.env.REACT_APP_IDENTITY_POOL_ID, // REQUIRED - Amazon Cognito Identity Pool ID
    region: process.env.REACT_APP_AWS_PROJECT_REGION,           // REQUIRED - Amazon Cognito Region
    userPoolId: process.env.REACT_APP_AWS_USER_POOLS_ID,         // OPTIONAL - Amazon Cognito User Pool ID
    userPoolWebClientId: process.env.REACT_APP_CLIENT_ID,   // OPTIONAL - Amazon Cognito Web Client ID (26-char alphanumeric string)
  }
});
```
- Add the following env-vars to the `front-end` service in the docker-compose file.
```Shell
REACT_APP_AWS_PROJECT_REGION: "{AWS_DEFAULT_REGION}"
REACT_APP_AWS_COGNITO_REGION: "{AWS_DEFAULT_REGION}"
REACT_APP_AWS_USER_POOLS_ID: "log in to Cognito to get it"
REACT_APP_CLIENT_ID: 'log into Cognito to get it, it is under App Integration section'
```
- Add these to the backend service code in the docker-compose file.
```Shell

```


- We are now going to show components based on whether they are logged in or logged out on our `frontend-react-js/src/pages/HomeFeedPage.js`.
	- import `import { Auth } from 'aws-amplify';` into the code
```Node
import './HomeFeedPage.css';
import React from "react";

import { Auth } from 'aws-amplify'; //new import

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function HomeFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null); //set state for app
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      const res = await fetch(backend_url, {
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

//replace the checkAUTH statement with a new one
  // check if we are authenicated
const checkAuth = async () => { 
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} /> //Desktop navigation set
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <ActivityFeed 
          title="Home" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} /> //sidebar set
    </article>
  );
}
```

- A little cleanup in the `frontend-react-js/src/components/DesktopSidebar.js` file
```Node
import './DesktopSidebar.css';
import Search from '../components/Search';
import TrendingSection from '../components/TrendingsSection'
import SuggestedUsersSection from '../components/SuggestedUsersSection'
import JoinSection from '../components/JoinSection'

export default function DesktopSidebar(props) {
  const trendings = [
    {"hashtag": "100DaysOfCloud", "count": 2053 },
    {"hashtag": "CloudProject", "count": 8253 },
    {"hashtag": "AWS", "count": 9053 },
    {"hashtag": "FreeWillyReboot", "count": 7753 }
  ]

  const users = [
    {"display_name": "Andrew Brown", "handle": "andrewbrown"}
  ]

  let trending;  //cleanup here
  let suggested;
  let join;
  if (props.user) {
    trending = <TrendingSection trendings={trendings} />
    suggested = <SuggestedUsersSection users={users} />
  } else {
    join = <JoinSection />
  }

  return (
    <section>
      <Search />
      {trending}
      {suggested}
      {join}
      <footer>
        <a href="#">About</a>
        <a href="#">Terms of Service</a>
        <a href="#">Privacy Policy</a>
      </footer>
    </section>
  );
}
```

- Rewriting the `frontend-react-js/src/components/DesktopNavigation.js` so that it conditionally shows links in the left-hand column on whether the user is logged in or not.
	- This information has to be passed to the `frontend-react-js/src/components/ProfileInfo.js`. It has a connection to the  `frontend-react-js/src/components/DesktopNavigation.js` code. 

```Javascript
//basically we are taking all the cookies away and replacing it with the user data.

import './ProfileInfo.css';
import {ReactComponent as ElipsesIcon} from './svg/elipses.svg';
import React from "react";

// [TODO] Authenication
import { Auth } from 'aws-amplify'; //import the AUTH library from AWS Amplify

export default function ProfileInfo(props) {
  const [popped, setPopped] = React.useState(false);

  const click_pop = (event) => {
    setPopped(!popped)
  }

  //replaced Cookies with real data
  const signOut = async () => {
    try {
        await Auth.signOut({ global: true });
        window.location.href = "/"
    } catch (error) {
        console.log('error signing out: ', error);
    }
  }

  const classes = () => {
    let classes = ["profile-info-wrapper"];
    if (popped == true){
      classes.push('popped');
    }
    return classes.join(' ');
  }

  return (
    <div className={classes()}>
      <div className="profile-dialog">
        <button onClick={signOut}>Sign Out</button> 
      </div>
      <div className="profile-info" onClick={click_pop}>
        <div className="profile-avatar"></div>
        <div className="profile-desc">
          <div className="profile-display-name">{props.user.display_name || "My Name" }</div>
          <div className="profile-username">@{props.user.handle || "handle"}</div>
        </div>
        <ElipsesIcon className='icon' />
      </div>
    </div>
  )
}
```

```Node
import './DesktopNavigation.css';
import {ReactComponent as Logo} from './svg/logo.svg';
import DesktopNavigationLink from '../components/DesktopNavigationLink';
import CrudButton from '../components/CrudButton';
import ProfileInfo from '../components/ProfileInfo';

export default function DesktopNavigation(props) {

  let button;
  let profile;
  let notificationsLink;
  let messagesLink;
  let profileLink;
  if (props.user) {
    button = <CrudButton setPopped={props.setPopped} />;
    profile = <ProfileInfo user={props.user} />;
    notificationsLink = <DesktopNavigationLink 
      url="/notifications" 
      name="Notifications" 
      handle="notifications" 
      active={props.active} />;
    messagesLink = <DesktopNavigationLink 
      url="/messages"
      name="Messages"
      handle="messages" 
      active={props.active} />
    profileLink = <DesktopNavigationLink 
      url="/@andrewbrown" 
      name="Profile"
      handle="profile"
      active={props.active} />
  }

  return (
    <nav>
      <Logo className='logo' />
      <DesktopNavigationLink url="/" 
        name="Home"
        handle="home"
        active={props.active} />
      {notificationsLink}
      {messagesLink}
      {profileLink}
      <DesktopNavigationLink url="/#" 
        name="More" 
        handle="more"
        active={props.active} />
      {button}
      {profile}
    </nav>
  );
}
```

### TAKE SOME TIME AND RESTART THE APP, IT SHOULD LOAD THE DEFAULT PAGE.

- Now we create the Sign-in page for the frontend, we go to the `frontend-react-js/src/pages/SignIn.js`
```Javascript
import './SigninPage.css';
import React from "react";
import {ReactComponent as Logo} from '../components/svg/logo.svg';
import { Link } from "react-router-dom";

// [TODO] Authenication
import { Auth } from 'aws-amplify'; //import AWS Amplify libraries

export default function SigninPage() {

  const [email, setEmail] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [errors, setErrors] = React.useState('');

  //change the onsubmit code
  const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
    .then(user => {
      console.log('user',user)
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken) //working on this later
      window.location.href = "/"
    })
    .catch(error => { //modify the error code 
      if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
    });
    return false
  }

  const email_onchange = (event) => {
    setEmail(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }

  return (
    <article className="signin-article">
      <div className='signin-info'>
        <Logo className='logo' />
      </div>
      <div className='signin-wrapper'>
        <form 
          className='signin_form'
          onSubmit={onsubmit}
        >
          <h2>Sign into your Cruddur account</h2>
          <div className='fields'>
            <div className='field text_field username'>
              <label>Email</label>
              <input
                type="text"
                value={email}
                onChange={email_onchange} 
              />
            </div>
            <div className='field text_field password'>
              <label>Password</label>
              <input
                type="password"
                value={password}
                onChange={password_onchange} 
              />
            </div>
          </div>
          {el_errors}
          <div className='submit'>
            <Link to="/forgot" className="forgot-link">Forgot Password?</Link>
            <button type='submit'>Sign In</button>
          </div>

        </form>
        <div className="dont-have-an-account">
          <span>
            Don't have an account?
          </span>
          <Link to="/signup">Sign up!</Link>
        </div>
      </div>

    </article>
  );
}
```

### TRY TO SIGN IN, YOU SHOULD BE GETTING PASSWORD IS INCORRECT OR ACCOUNT DOESN'T EXIST. IF SO TRY RECREATING THE USER POOL AGAIN (USE PUBLIC CLIENT AS APP TYPE IN STEP 6)

### TRY SIGNING IN AGAIN, YOU SHOULD GET AN ERROR SAYING THE USERNAME OR PASSWORD IS INCORRECT

- Go into the Cognito user pool and create a user manually; enable email, send an invitation.
- Log into the account with said username, email and password.


## Continuation
- To get the code working, eliminating the "Force Password Change" in the Cognito user section; we have to add run some code in AWS to make Cognito confirm the password.
	- we set a permanent user-password for admin (our user) in Cognito
```Shell
aws cognito-idp admin-set-user-password \
--user-pool-id eu-west-2_vt2BklInQ \
--username ernestklu \
--password Testing1234@ \
--permanent
```
- with this we can confirm our account and the changes will be permanent.
- After we get the SignIn page/code working, go ahead and add user attributes "name" and "preferred username" and that will be propagated in the left-hand column of the Cruddur app so signify the user we are logged in as.
	- SPIN UP THE SERVICES AND TEST TO CHECK IF RESPONDING ACCURATELY.
	- Go ahead and delete this user when done.
	- reason for deleting is that, we do not want to use the AWS Cognito to handle our signing in and up processes, it helps BUT we want to keep things local.

- Go on ahead to rewrite the SignUp page. It should look like this. in the `frontend-react-js/src/pages/SignupPage.js`
```Javascript
import './SignupPage.css';
import React from "react";
import {ReactComponent as Logo} from '../components/svg/logo.svg';
import { Link } from "react-router-dom";

// [TODO] Authenication
import { Auth } from 'aws-amplify'; //import Auth library from Amplify

export default function SignupPage() {

  // Username is Eamil
  const [name, setName] = React.useState('');
  const [email, setEmail] = React.useState('');
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [errors, setErrors] = React.useState('');

  // change the onsubmit code to reflect what will be seen in the SignUp page
  const onsubmit = async (event) => {
    event.preventDefault();
    setCognitoErrors('')
    try {
      const { user } = await Auth.signUp({
        username: email,
        password: password,
        attributes: {
            name: name,
            email: email,
            preferred_username: username,
        },
        autoSignIn: { // optional - enables auto sign in after user is confirmed
            enabled: true,
        }
      });
      console.log(user);
      window.location.href = `/confirm?email=${email}`
    } catch (error) {
        console.log(error);
        setCognitoErrors(error.message)
    }
    return false
  }

  const name_onchange = (event) => {
    setName(event.target.value);
  }
  const email_onchange = (event) => {
    setEmail(event.target.value);
  }
  const username_onchange = (event) => {
    setUsername(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }

  return (
    <article className='signup-article'>
      <div className='signup-info'>
        <Logo className='logo' />
      </div>
      <div className='signup-wrapper'>
        <form 
          className='signup_form'
          onSubmit={onsubmit}
        >
          <h2>Sign up to create a Cruddur account</h2>
          <div className='fields'>
            <div className='field text_field name'>
              <label>Name</label>
              <input
                type="text"
                value={name}
                onChange={name_onchange} 
              />
            </div>

            <div className='field text_field email'>
              <label>Email</label>
              <input
                type="text"
                value={email}
                onChange={email_onchange} 
              />
            </div>

            <div className='field text_field username'>
              <label>Username</label>
              <input
                type="text"
                value={username}
                onChange={username_onchange} 
              />
            </div>

            <div className='field text_field password'>
              <label>Password</label>
              <input
                type="password"
                value={password}
                onChange={password_onchange} 
              />
            </div>
          </div>
          {el_errors}
          <div className='submit'>
            <button type='submit'>Sign Up</button>
          </div>
        </form>
        <div className="already-have-an-account">
          <span>
            Already have an account?
          </span>
          <Link to="/signin">Sign in!</Link>
        </div>
      </div>
    </article>
  );
}
```

- Rewrite the Confirmation page that comes after the SignUp page. Code in the `frontend-react-js/src/pages/ConfirmationPage.js`
```Javascript
import './ConfirmationPage.css';
import React from "react";
import { useParams } from 'react-router-dom';
import {ReactComponent as Logo} from '../components/svg/logo.svg';

// [TODO] Authenication
import { Auth } from 'aws-amplify'; //import the Auth library from Amplify

export default function ConfirmationPage() {
  const [email, setEmail] = React.useState('');
  const [code, setCode] = React.useState('');
  const [errors, setErrors] = React.useState('');
  const [codeSent, setCodeSent] = React.useState(false);

  const params = useParams();

  const code_onchange = (event) => {
    setCode(event.target.value);
  }
  const email_onchange = (event) => {
    setEmail(event.target.value);
  }

  //change resend code to process data
  const resend_code = async (event) => {
    setErrors('')
    try {
      await Auth.resendSignUp(email);
      console.log('code resent successfully');
      setCodeSent(true)
    } catch (err) {
      // does not return a code
      // does cognito always return english
      // for this to be an okay match?
      console.log(err)
      if (err.message == 'Username cannot be empty'){
        setErrors("You need to provide an email in order to send Resend Activiation Code")   
      } else if (err.message == "Username/client id combination not found."){
        setErrors("Email is invalid or cannot be found.")   
      }
    }
  }

  //change the onsubmit code
  const onsubmit = async (event) => {
    event.preventDefault();
    setErrors('')
    try {
      await Auth.confirmSignUp(email, code);
      window.location.href = "/"
    } catch (error) {
      setErrors(error.message)
    }
    return false
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }


  let code_button;
  if (codeSent){
    code_button = <div className="sent-message">A new activation code has been sent to your email</div>
  } else {
    code_button = <button className="resend" onClick={resend_code}>Resend Activation Code</button>;
  }

  React.useEffect(()=>{
    if (params.email) {
      setEmail(params.email)
    }
  }, [])

  return (
    <article className="confirm-article">
      <div className='recover-info'>
        <Logo className='logo' />
      </div>
      <div className='recover-wrapper'>
        <form
          className='confirm_form'
          onSubmit={onsubmit}
        >
          <h2>Confirm your Email</h2>
          <div className='fields'>
            <div className='field text_field email'>
              <label>Email</label>
              <input
                type="text"
                value={email}
                onChange={email_onchange} 
              />
            </div>
            <div className='field text_field code'>
              <label>Confirmation Code</label>
              <input
                type="text"
                value={code}
                onChange={code_onchange} 
              />
            </div>
          </div>
          {el_errors}
          <div className='submit'>
            <button type='submit'>Confirm Email</button>
          </div>
        </form>
      </div>
      {code_button}
    </article>
  );
}
```
- After getting the user to Sign Up, confirm the user in the Cognito page. It should show that the email is verified. It should send an email with a verfication code that will be used in the Confirmation page.
- Before you test, recreate the user-pool and make sure only "email" is used to sign in (no "User name")
TEST TO CHECK IF EVERYTHING IS WORKING IN ORDER SO FAR

- Rewriting the RecoverPage code so a user can recover their password. A verification code should be sent when the action is performed.
- Change the `frontend-react-js/src/pages/RecoverPage.js` code as such;
```Javascript
import './RecoverPage.css';
import React from "react";
import {ReactComponent as Logo} from '../components/svg/logo.svg';
import { Auth } from 'aws-amplify'; //import Auth from AWS Amplify
import { Link } from "react-router-dom";

export default function RecoverPage() {
  // Username is Eamil
  const [username, setUsername] = React.useState('');
  const [password, setPassword] = React.useState('');
  const [passwordAgain, setPasswordAgain] = React.useState('');
  const [code, setCode] = React.useState('');
  const [errors, setErrors] = React.useState('');
  const [formState, setFormState] = React.useState('send_code');

  //change the onsubmit_send_code
  const onsubmit_send_code = async (event) => {
    event.preventDefault();
    setCognitoErrors('')
    Auth.forgotPassword(username)
    .then((data) => setFormState('confirm_code') )
    .catch((err) => setCognitoErrors(err.message) );
    return false
  }

  //change the onsubmit_confirm_code
  const onsubmit_confirm_code = async (event) => {
    event.preventDefault();
    setCognitoErrors('')
    if (password == passwordAgain){
      Auth.forgotPasswordSubmit(username, code, password)
      .then((data) => setFormState('success'))
      .catch((err) => setCognitoErrors(err.message) );
    } else {
      setCognitoErrors('Passwords do not match')
    }
    return false
  }

  const username_onchange = (event) => {
    setUsername(event.target.value);
  }
  const password_onchange = (event) => {
    setPassword(event.target.value);
  }
  const password_again_onchange = (event) => {
    setPasswordAgain(event.target.value);
  }
  const code_onchange = (event) => {
    setCode(event.target.value);
  }

  let el_errors;
  if (errors){
    el_errors = <div className='errors'>{errors}</div>;
  }

  const send_code = () => {
    return (<form 
      className='recover_form'
      onSubmit={onsubmit_send_code}
    >
      <h2>Recover your Password</h2>
      <div className='fields'>
        <div className='field text_field username'>
          <label>Email</label>
          <input
            type="text"
            value={username}
            onChange={username_onchange} 
          />
        </div>
      </div>
      {el_errors}
      <div className='submit'>
        <button type='submit'>Send Recovery Code</button>
      </div>

    </form>
    )
  }

  const confirm_code = () => {
    return (<form 
      className='recover_form'
      onSubmit={onsubmit_confirm_code}
    >
      <h2>Recover your Password</h2>
      <div className='fields'>
        <div className='field text_field code'>
          <label>Reset Password Code</label>
          <input
            type="text"
            value={code}
            onChange={code_onchange} 
          />
        </div>
        <div className='field text_field password'>
          <label>New Password</label>
          <input
            type="password"
            value={password}
            onChange={password_onchange} 
          />
        </div>
        <div className='field text_field password_again'>
          <label>New Password Again</label>
          <input
            type="password"
            value={passwordAgain}
            onChange={password_again_onchange} 
          />
        </div>
      </div>
      {errors}
      <div className='submit'>
        <button type='submit'>Reset Password</button>
      </div>
    </form>
    )
  }

  const success = () => {
    return (<form>
      <p>Your password has been successfully reset!</p>
      <Link to="/signin" className="proceed">Proceed to Signin</Link>
    </form>
    )
    }

  let form;
  if (formState == 'send_code') {
    form = send_code()
  }
  else if (formState == 'confirm_code') {
    form = confirm_code()
  }
  else if (formState == 'success') {
    form = success()
  }

  return (
    <article className="recover-article">
      <div className='recover-info'>
        <Logo className='logo' />
      </div>
      <div className='recover-wrapper'>
        {form}
      </div>

    </article>
  );
}
```

- Try recovering the password from the Recovery Page.
- Go through the process and get the Recovery to work.



## Implementing a JWT token in the backend

- From the SignIn page we passed in code that was supposed to store a JWT token in local storage. Code Snippet:
```Javascript
const onsubmit = async (event) => {
    setErrors('')
    event.preventDefault();
    Auth.signIn(email, password)
    .then(user => {
      console.log('user',user)
      localStorage.setItem("access_token", user.signInUserSession.accessToken.jwtToken //JWT token passed in SignIn Page.
      window.location.href = "/"
    })
    .catch(error => { //modify the error code 
      if (error.code == 'UserNotConfirmedException') {
        window.location.href = "/confirm"
      }
      setErrors(error.message)
    });
    return false
  }
```
- For decentralized authentication, we need to pass these along in the API calls, so we implement some headers that will pass in that token. We take the HomeFeedPage, it has some lines that call the backend, so it has to pass along that token.
```Javascript
import './HomeFeedPage.css';
import React from "react";

import { Auth } from 'aws-amplify'; //new import

import DesktopNavigation  from '../components/DesktopNavigation';
import DesktopSidebar     from '../components/DesktopSidebar';
import ActivityFeed from '../components/ActivityFeed';
import ActivityForm from '../components/ActivityForm';
import ReplyForm from '../components/ReplyForm';

// [TODO] Authenication
import Cookies from 'js-cookie'

export default function HomeFeedPage() {
  const [activities, setActivities] = React.useState([]);
  const [popped, setPopped] = React.useState(false);
  const [poppedReply, setPoppedReply] = React.useState(false);
  const [replyActivity, setReplyActivity] = React.useState({});
  const [user, setUser] = React.useState(null); //set state for app
  const dataFetchedRef = React.useRef(false);

  const loadData = async () => {
    try {
      const backend_url = `${process.env.REACT_APP_BACKEND_URL}/api/activities/home`
      const res = await fetch(backend_url, {
        headers :{ 
	        Authorization: `Bearer ${localStorage.getItem("access_token")}` //passing along the JWT token
        },
        method: "GET"
      });
      let resJson = await res.json();
      if (res.status === 200) {
        setActivities(resJson)
      } else {
        console.log(res)
      }
    } catch (err) {
      console.log(err);
    }
  };

//replace the checkAUTH statement with a new one
  // check if we are authenicated
const checkAuth = async () => { 
  Auth.currentAuthenticatedUser({
    // Optional, By default is false. 
    // If set to true, this call will send a 
    // request to Cognito to get the latest user data
    bypassCache: false 
  })
  .then((user) => {
    console.log('user',user);
    return Auth.currentAuthenticatedUser()
  }).then((cognito_user) => {
      setUser({
        display_name: cognito_user.attributes.name,
        handle: cognito_user.attributes.preferred_username
      })
  })
  .catch((err) => console.log(err));
};

  React.useEffect(()=>{
    //prevents double call
    if (dataFetchedRef.current) return;
    dataFetchedRef.current = true;

    loadData();
    checkAuth();
  }, [])

  return (
    <article>
      <DesktopNavigation user={user} active={'home'} setPopped={setPopped} /> //Desktop navigation set
      <div className='content'>
        <ActivityForm  
          popped={popped}
          setPopped={setPopped} 
          setActivities={setActivities} 
        />
        <ReplyForm 
          activity={replyActivity} 
          popped={poppedReply} 
          setPopped={setPoppedReply} 
          setActivities={setActivities} 
          activities={activities} 
        />
        <ActivityFeed 
          title="Home" 
          setReplyActivity={setReplyActivity} 
          setPopped={setPoppedReply} 
          activities={activities} 
        />
      </div>
      <DesktopSidebar user={user} /> //sidebar set
    </article>
  );
}
```

-  check the app.py and cognito_jwt_token.py and files in the backend.
- In these files are code to configure the backend to receive authorization tokens generated from the user signing in/up to authenticate the user (plus for local storage.)
