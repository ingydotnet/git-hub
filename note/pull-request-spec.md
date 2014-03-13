##The Dream

 * `git hub clone foo/bar`
 * find bug
 * `git checkout -b fix-bug`
 * fix bug
 * `gut hub fork --with-remote frioux`
 * `git push frioux fix-bug`
 * `git hub pull-request --to foo` (*maybe* default --to if it's a fork?)

git-hub should then:

 * Error if you forgot to fork/push (or maybe optionally offer to do it for you? `git hub pull-request --to foo --dwim`)
 * Pop up an editor a la `git commit`
   * first line of editor is title of PR (can be set with --title maybe?)
   * third and following are the body (can be skipped with --no-body?)
   * below the body include a full diff of the pull-request, like if the user had done git commit -av
   * as with git commit, if the title is empty, exit saying "nothing to PR" or something

##The Moon

 * Author gets email mentioning PR
 * `git hub pulls` lists the oustanding PR's
 * `git hub pull 34 --fetch` fetches PR#34 into FETCH_HEAD (this is just `git fetch origin refs/pull/34/head`)
 * `git hub pull 34` merges #34 in and closes PR#34 (maybe with an autopush?  Note I would never use this command so feel free to ignore it)
 * `git hub pull 34 --close --message 'Merged'` This is what I'd do, after a manual merge
