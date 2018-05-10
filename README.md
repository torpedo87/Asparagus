# Asparagus
- [AppStore](https://itunes.apple.com/us/app/asparagus/id1361881261?mt=8)
- To-Do-List + Issue Tracker
- Manage your custom issue in Local or connect with your Github issues
- Sync with your Github project
- Seperate a issue into sub-tasks
- Attach custom tags to issues

## spec
- Realm
- RxSwift

## app architecture
- SyncService <-> LocalService <-> ViewModel <-> ViewController
- AuthView : Connect with your Github Issues
- TaskView : Issue List by Tags
- EditView : Create new issue or edit existing issue
- SettingView : Opensource license info

## 유레카
- Realm managed object는 thread 간 이동시 threadSafe 를 보장해주어야 한다
