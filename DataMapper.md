# Introduction #

The MSDataMapper class has been provided to map the data structure in the web service response to a different structure to enable re-use of different handlers with similar data structures.  This also allows you to change service implementations without necessarily changing the code that consumes it.

# Details #

Requests that are initiated through the MSSDK class will be automatically transformed through the MSDataMappers that are configured in MySpaceSDKServices.plist in the MySpaceSDK project.  This services config file contains the following entries for each service key

### serviceURL ###

This is the URL for the service, which is loaded by the service key in the top-level dictionary.  To change the service implementation used for any particular service, you simply change this value in the plist.

### objectArrayKeyPath ###

For services that return multiple objects, this value will give the key path for the array of objects in the response.  Depending on which base service you are using, this value may be different (ex: data or entry)

### objectAttributes ###

This is a dictionary of attributes to map from the response into the data object(s).  The key is the output attribute name, the value is the key path for the value to read from the input (directly from the service response).

### objectFormatters ###

This is a dictionary of formatters to apply to the output attributes.  The key is the name of the attribute (see objectAttributes above) and the value is the type of formatter to use for that value.  Available formatters include html, url, date, integer.


---


You can use the data mappers that are loaded from the config through [[sharedSDK](MSSDK.md) dataMappers] or you can construct you own.  To map dictionaries of data, you can simply call [mapData:inputData](dataMapper.md) to get the formatted data structure.