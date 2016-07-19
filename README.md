# bb

## A. Summary

**bb**, or "Bash Blog", is a lightning-fast, secure, flat-file blog publishing platform. It uses markdown syntax for super-easy content authoring, and StrapdownJS to make it look pretty!

Forget about painful file and database replication: **bb** can publish content both locally and remotely, right out of the box!

Editing is simply done in a "local" repository, while "public" content is generated from the local repository and then pushed to content hosts.

The flow for creating a new post is as follows:

`New post -> Edit content -> Set post status to 'publish' -> Generate content -> Push`

To get started using markdown, see: [1](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet) and [2](https://github.com/tchapi/markdown-cheatsheet/blob/master/README.md) - you can even use this very `README.md` as a markdown example!

## B. Dependencies

 * rsync
 * openssl (for content hash calculation)
 * openssh client

## C. Supported Systems

Tested on BASH 3.2 (OS X) and BASH 4.1.2 on CentOS Linux.

### Installation

 * Clone this repo to your preferred directory (eg: `/opt/bb`)

`git clone https://github.com/curtis86/bb`

 * Update your `bb.conf` file to define your blog name, subtitle, etc

`vim /opt/bb/bb.conf`

 * Define hosts to push content to in `hosts.txt`

For example, to push content to local directory `/var/www/bb`, the host line would be:

`local,/var/www/bb`

And, to push content to remote host *192.168.17.207* as user *bb*, to directory `/var/www/bb`, the host line would be:

`remote,192.168.17.207,bb,/var/www/bb`

You can have a line-separated mix of local and remotes.

### Usage

```
Usage: bb <options>

OPTIONS
 new <post title>                   Creates a new post with specified title
 edit <id>                          Edits post by ID
 set <id> [publish|unpublish]       Sets post status to 'publish' or 'unpublish'
 delete <id>                        Deletes post by ID
 list                               Lists all posts
 generate                           Generates 'public' output
 push                               Pushes latest generated content to servers
```

### Sample output

* Create a new post, add content, set status to publish, generate content and push:

```
# ./bb new "This is my first post"

Creating new post...
Title: This is my first post
ID: 0

New post created. To create content for this post, edit: /opt/bb/repository/local/0/content

# ./bb edit 0

# ./bb set 0 publish

Post ID 0 set to: publish

./bb generate

Generating posts...

Generating post ID: 0

Generating index...

Latest content has been generated. Please run the push command to push the latest content.

./bb push
Pushing to local directory /var/www/html/bb-test:  OK
Pushing to remote 192.168.17.207:/var/www/html/bb-test: OK

Push complete.
```

* Unpublish a post

```
./bb set 0 unpublish

Post ID 0 set to: unpublish
```

Note: when setting a post to 'publish' or 'unpublish' you **must** re-run the generate and push functions to ensure your public/live content is up to date.

* Delete a post

```
./bb delete 0
Are you sure you want to delete post ID 0 ? <y/n> y
```

* Quick generate & push
 
```
./bb generate && ./bb push
```

## Notes

* Editing a posts' content is as simple as editing the `content` file of the post in the local repository (`repositories/local/id`). 
* For post-specific images, create an `assets` directory in the post's local repository directory. This will be pushed automatically.
* For shared images, add them to the public directory's `assets` directory.

## TODO

See [bb Issues](https://github.com/curtis86/bb/issues)

## Disclaimer

I'm not a programmer, but I do like to make things! Please use this at your own risk.

## License

The MIT License (MIT)

Copyright (c) 2016 Curtis K

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
