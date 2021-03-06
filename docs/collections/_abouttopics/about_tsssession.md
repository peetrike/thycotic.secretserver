---
category: authentication
title: "TssSession"
last_modified_at: 2021-02-10T00:00:00-00:00
---

# TOPIC
    This help topic describes the TssSession class in the Thycotic.SecretServer module.

# CLASS
    TssSession

# INHERITANCE
    None

# DESCRIPTION
    The TssSession class represents an authenticated object to Secret Server.
    New-TssSession is used to create an instance of this class type.

# CONSTRUCTORS
    new()

# PROPERTIES
    SecretServer:
        Secret Server base URL

    AccessToken:
        Authentication token

    RefreshToken:
        Authentication token (when using refresh_token grant type)

    ExpiresIn:
        Authentication token expiration time, in seconds

    TokenType:
        Authentication token type

    StartTime:
        Current date and time when session was created
        Hidden property

    TimeOfDeath:
        Expiration date and time based on ExpiresIn value.
        Provides the time when the authentication token will no longer be valid.
        Hidden property

# METHODS

    [boolean] IsValidSession()
        Validates the AccessToken and RefreshToken are set on the object
        Checks that StartTime is not set to '0001-01-01 00:00:00'

    [boolean] IsValidToken()
        Validates AccessToken is set
        Validates that TimeOfDeath is less than current time
        Validates that TimeOfDeath is not greater than current time

    [boolean] SessionExpire()
        POST to oauth-expiration endpoint of Secret Server to expire the session
        for the current AccessToken
        If endpoint call fails will return false

    [boolean] SessionRefresh()
        Post to oauth2/token endpoint of Secret Server utilizing the RefreshToken
        to re-authenticate
        It will update the current object properties with the new associated values
        I endpoint call fails will return error

# RELATED LINKS:
    New-TssSession