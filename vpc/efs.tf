resource "aws_efs_file_system" "amundsen" {
}

# declare mount target for each subnet
resource "aws_efs_mount_target" "amundsen" {
    count = length(aws_subnet.private)
    file_system_id = aws_efs_file_system.amundsen.id
    subnet_id      = aws_subnet.private[count.index].id
    security_groups = [ aws_security_group.amundsen.id ]
}

# define access point for neo4j_data
resource "aws_efs_access_point" "neo4j_data" {
  file_system_id = aws_efs_file_system.amundsen.id
  posix_user {
    gid = 1000 # for amundsen, important that same gui/uid used across each access point
    uid = 1000
  }
  root_directory {
    path = "/neo4j/data"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}

# define access point for neo4j_backup
resource "aws_efs_access_point" "neo4j_backup" {
  file_system_id = aws_efs_file_system.amundsen.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/backup"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}

# define access point for neo4j_conf
resource "aws_efs_access_point" "neo4j_conf" {
  file_system_id = aws_efs_file_system.amundsen.id
  posix_user {
    gid = 1000
    uid = 1000
  }
  root_directory {
    path = "/conf"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 755
    }
  }
}
