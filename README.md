# <a href="https://itunes.apple.com/us/app/asparagus/id1361881261?mt=8"><img src="/Screenshots/icon.png" width="100" height="100"/></a> Asparagus


<p align="center"><a href="https://itunes.apple.com/us/app/asparagus/id1361881261?mt=8"><img src="Screenshots/app-store-badge.png" width="250" /></a></p>

- To-Do-List + Issue Tracker
- Manage your issues only for Today just like to-do-lists apps
- Manage one issue with detailed a few check-lists
- Simply create and close your Github issues
- When you are offline, you can manage your issues in local
- As soon as your state become online, you can sync your data changes with Github automatically

![Alt text](/Screenshots/allshots.png)


## spec

- Realm
- RxSwift


## app architecture

- SyncService <-> LocalService <-> ViewModel <-> ViewController
- SyncView : Sync with Github Issues
- RepositoryView : Github repository list
- IssueView : Github issue list per repository, Open/Close issue, Check star/unstar issue for Today
- IssueDetailView : Create new issue, Edit existing issue
- PopupView : Manage label, assignee, checklist of issue


## 유레카

- Realm managed object는 thread 간 이동시 threadSafe 를 보장해주어야 한다
