using namespace Thycotic.SecretServer.Sdk.Extensions.Integration.Clients;
using namespace Thycotic.SecretServer.Sdk.Extensions.Integration.Models;
using namespace Thycotic.SecretServer.Sdk.Infrastructure.Models;

$config = [Thycotic.SecretServer.Sdk.Extensions.Integration.Models.ConfigSettings]::new()
$config.RuleName = 'tssmodule'
$config.CacheAge = 30
$config.CacheStrategy = 0
$config.SecretServerUrl = 'http://vault3'

$client = [Thycotic.SecretServer.Sdk.Extensions.Integration.Clients.SecretServerClient]::new()
$client.Configure($config,$true)

$client.Configure()

$s = New-TssSession -SecretServer 'http://vault3' -AccessToken $client.GetAccessToken()
Get-TssSecret -TssSession $s -Id 19