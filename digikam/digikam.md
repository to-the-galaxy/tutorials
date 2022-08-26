# DigiKam and workflow

## Database

It is easy to move databases from the application itself.

## Photo collections

- DigiKam > Settings > Configure DigiKam... > Collections
- Add relevant paths

## Backup using rsync

`rsync -avzh /home/michael/DigiKam-photo-library/ /mnt/nfs/DigiKam-backup/`

Add `--dry-run` to test.

```
rsync -avzh /home/michael/DigiKam-photo-library/ /mnt/nfs/DigiKam-backup/ --exclude '@eaDir'
```

## To-Do

How to restore a DigiKam-database?
