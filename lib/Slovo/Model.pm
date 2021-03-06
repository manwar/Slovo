package Slovo::Model;
use Mojo::Base -base, -signatures;
use feature qw(lexical_subs unicode_strings);
## no critic qw(TestingAndDebugging::ProhibitNoWarnings)
no warnings "experimental::lexical_subs";


has 'dbx';
has c => sub { Slovo::Controller->new() };
sub table { Carp::croak 'Method not implemented' }

sub all ($self, $opts = {}) {
  $opts->{limit} //= 100;
  $opts->{limit} = 100 unless $opts->{limit} =~ /^\d+$/;
  $opts->{offset} //= 0;
  $opts->{offset} = 0 unless $opts->{offset} =~ /^\d+$/;
  $opts->{where} //= {};
  $opts->{order_by} //= {-asc => ['id', 'pid', 'sorting']};

  # $self->c->debug('opts:', $opts);
  state $abstr = $self->dbx->abstract;
  my ($sql, @bind)
    = $abstr->select($opts->{table} // $self->table,
                     $opts->{columns}, $opts->{where}, $opts->{order_by});
  $sql .= " LIMIT $opts->{limit}"
    . ($opts->{offset} ? " OFFSET $opts->{offset}" : '');

  # local $self->dbx->db->dbh->{TraceLevel} = "3|SQL";
  return $self->dbx->db->query($sql, @bind)->hashes;
}

#update a record
sub save ($self, $id, $row) {

  # local $self->dbx->db->dbh->{TraceLevel} = "3|SQL";
  return $self->dbx->db->update($self->table, $row, {id => $id});
}

sub find_where ($m, $where = {1 => 1}) {

  # local $m->dbx->db->dbh->{TraceLevel} = "3|SQL";
  state $abstr = $m->dbx->abstract;
  my ($sql, @bind) = $abstr->where($where);
  return $m->dbx->db->query("SELECT * FROM ${\ $m->table } $sql LIMIT 1", @bind)
    ->hash;
}

sub find {
  return $_[0]->dbx->db->select($_[0]->table, undef, {id => $_[1]})->hash;
}

sub remove {
  return $_[0]->dbx->db->delete($_[0]->table, {id => $_[1]});
}

sub add {

  # local $_[0]->dbx->db->dbh->{TraceLevel} = "3|SQL";
  return $_[0]->dbx->db->insert($_[0]->table, $_[1])->last_insert_id;
}

# Returns hashref for where clause where permissions allow the user to read
#records.
sub readable_by ($self, $user) {
  my $t = $self->table;
  return {
    -or => [

      # everybody can read
      {"$t.permissions" => {-like => '%r__'}},

      # user is owner
      {
       "$t.user_id" => $user->{id},

       # "$table.permissions" => {-like => '_r__%'}
      },

      # a page, which can be read
      # by one of the groups to which this user belongs.
      {
       "$t.permissions" => {-like => '____r__%'},

    # TODO: Implement 'adding users to multiple groups in /Ꙋправленѥ/users/:id':
       "$t.group_id" => \[
           "IN (SELECT group_id from user_group WHERE user_id=?)" => $user->{id}
       ],
      },
    ],
  };
}

# Returns hashref for where clause where permissions allow the user to write
# records.
sub writable_by ($self, $user) {
  my $t = $self->table;
  return {
    -or => [

      # everybody can write
      {"$t.permissions" => {-like => '%_w_'}},

      # user is owner
      {"$t.user_id" => $user->{id}, "$t.permissions" => {-like => '__w_%'}},

      # a page, which can be written
      # by one of the groups to which this user belongs.
      {
       "$t.permissions" => {-like => '_____w_%'},

    # TODO: Implement 'adding users to multiple groups in /Ꙋправленѥ/users/:id':
       "$t.group_id" => \[
           "IN (SELECT group_id from user_group WHERE user_id=?)" => $user->{id}
       ],
      },
    ],
  };
}


1;


