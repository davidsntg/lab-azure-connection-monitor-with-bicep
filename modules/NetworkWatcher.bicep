param networkWatcherName string
param location string

resource NetworkWatcher 'Microsoft.Network/networkWatchers@2021-05-01' = {
  name: networkWatcherName
  location: location
}
