package Bric::Biz::AssetType::Parts::Data::DevTest;
use strict;
use warnings;
use base qw(Bric::Test::DevBase);
use Test::More;
use Test::Exception;
use Bric::Biz::AssetType;
use Bric::Biz::OutputChannel;
use Bric::Util::DBI qw(:junction);

my %field = (
    key_name      => 'test_paragraph',
    name          => 'Test Paragraph',
    description   => 'Foo description',
    place         => 1,
    required      => 1,
    quantifier    => 1,
    autopopulated => 0,
    publishable   => 1,
    max_length    => 0,
    default_val  => '',
    sql_type      => 'short',
);

my $para_id = 1;
my $column_elem_id = 2;

sub table { 'at_data' };

sub element_type {
    my $self = shift;
    my $elem = Bric::Biz::AssetType->new({
        name          => 'Test Element Data',
        key_name      =>'test_field_type',
        description   => 'Testing Element Data API',
        burner        => Bric::Biz::AssetType::BURNER_MASON,
        type__id      => 1,
        reference     => 0,
        primary_oc_id => 1
    })->save;
    $self->add_del_ids([$elem->get_id], 'element_type');
    $self->add_del_ids([$elem->get_at_grp__id], 'grp');
    return $elem;
}

##############################################################################
# Test constructors.
##############################################################################
# Test new().
sub test_const : Test(44) {
    my $self = shift;

    ok my $elem = $self->element_type, "Get new element type object";
    $field{element_type_id} = $elem->get_id;

    ok( my $field = Bric::Biz::AssetType::Parts::Data->new,
        "Create empty field type" );
    isa_ok($field, 'Bric::Biz::AssetType::Parts::Data');
    isa_ok($field, 'Bric');

    ok( $field = Bric::Biz::AssetType::Parts::Data->new(\%field),
        "Create a new field");

    # Check the attributes.
    for my $attr (keys %field) {
        my $meth = "get_$attr";
        is $field->$meth, $field{$attr}, "Check $attr";
    }

    # Save it.
    ok $field->save, "Save the new field";
    my $fid = $field->get_id;
    $self->add_del_ids($fid);

    # Now look it up.
    ok $field = Bric::Biz::AssetType::Parts::Data->lookup({ id => $fid }),
      "Look it up again";
    is $field->get_id, $fid, "It should have the same ID";

    # Check the attributes again.
    for my $attr (keys %field) {
        my $meth = "get_$attr";
        is $field->$meth, $field{$attr}, "Check $attr";
    }

}

##############################################################################
# Test the list() method.
sub test_list : Test(90) {
    my $self = shift;

    ok my $elem = $self->element_type, "Get new element type object";
    $field{element_type_id} = $elem->get_id;

    # Create some test records.
    for my $n (1..5) {
        my %args = %field;
        # Make sure the name is unique.
        $args{key_name}     .= $n;
        $args{name}         .= $n;
        $args{description}  .= $n if $n % 2;
        $args{place}         = $n + 100;
        $args{quantifier}    = 0 if $n % 2;
        $args{required}      = 0 if $n % 2;
        $args{autopopulated} = 1 if $n % 2;
        $args{publishable}   = 0 unless $n % 2;
        $args{max_length}    = $n + 100;
        $args{sql_type}      = 'blob'     if $n % 2;
        $args{widget_type}   = 'textarea' if $n % 2;
        $args{cols}          = $n;
        $args{rows}          = $n;
        $args{length}        = $n;
        $args{default_val}   = "foo$n";
        ok( my $field = Bric::Biz::AssetType::Parts::Data->new(\%args),
            "Create $args{key_name}" );
        ok( $field->save, "Save $args{key_name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$field->get_id]);
    }

    # Try key_name + wildcard.
    ok( my @fields = Bric::Biz::AssetType::Parts::Data->list({
        key_name => "$field{key_name}%"
    }), "Look up key_name $field{key_name}%" );
    is( scalar @fields, 5, "Check for 5 fields" );
    isa_ok $_, 'Bric::Biz::AssetType::Parts::Data' for @fields;

    # Try ANY key_name.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        key_name => ANY("$field{key_name}1", "$field{key_name}2"),
    }), qq{Look up key_name ANY("$field{key_name}1", "$field{key_name}2")} );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try name.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        name => "$field{name}1"
    }), "Look up name $field{name}1" );
    is( scalar @fields, 1, "Check for 1 field" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        name => "$field{name}%"
    }), "Look up name $field{name}%" );
    is( scalar @fields, 5, "Check for 5 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        name => ANY("$field{name}1", "$field{name}2"),
    }), qq{Look up name ANY("$field{name}1", "$field{name}2")} );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try description.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        description => "$field{description}"
    }), "Look up description '$field{description}'" );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try ANY description.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        description => ANY("$field{description}", "$field{description}2"),
    }), qq{Look up description ANY("$field{description}", "$field{description}2")} );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try element_type_id.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
    }), "Lookup element_type_id $field{element_type_id}," );
    is( scalar @fields, 5, "Check for 5 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => ANY($field{element_type_id}, -101),
    }), "Lookup element_type_id ANY($field{element_type_id}, -101)" );
    is( scalar @fields, 5, "Check for 5 fields" );

    # Try place.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({ place => 101 }),
        "Lookup place 1" );
    is( scalar @fields, 1, "Check for 1 field" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        place => ANY(101, 102, 103)
    }), "Lookup place ANY(101, 102, 103)" );
    is( scalar @fields, 3, "Check for 3 fields" );

    # Try quantifier.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        quantifier => 1
    }), "Lookup quantifier 1" );
    is( scalar @fields, 2, "Check for 2 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        quantifier => 0
    }), "Lookup quantifier 0" );
    is( scalar @fields, 3, "Check for 3 fields" );

    # Try required.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_id => $field{element_type_id},
        required   => 1
    }), "Lookup required 1" );
    is( scalar @fields, 2, "Check for 2 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        required   => 0
    }), "Lookup required 0" );
    is( scalar @fields, 3, "Check for 3 fields" );

    # Try autopopulated.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id    => $field{element_type_id},
        autopopulated => 1
    }), "Lookup autopopulated 1" );
    is( scalar @fields, 3, "Check for 3 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id    => $field{element_type_id},
        autopopulated => 0
    }), "Lookup autopopulated 0" );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try publishable.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id    => $field{element_type_id},
        publishable => 1
    }), "Lookup publishable 1" );
    is( scalar @fields, 3, "Check for 3 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id    => $field{element_type_id},
        publishable => 0
    }), "Lookup publishable 0" );
    is( scalar @fields, 2, "Check for 2 fields" );

    # Try max_length.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        max_length => 101,
    }), "Lookup max_length 1" );
    is( scalar @fields, 1, "Check for 1 field" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        max_length => ANY(101, 102, 103),
    }), "Lookup max_length ANY(101, 102, 103)" );
    is( scalar @fields, 3, "Check for 3 fields" );

    # Try sql_type.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        sql_type   => 'short',
    }), "Lookup sql_type short" );
    is( scalar @fields, 2, "Check for 2 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        sql_type   => ANY('short', 'blob'),
    }), "Lookup sql_type ANY('short', 'blob')" );
    is( scalar @fields, 5, "Check for 5 fields" );

    # Try widget_type.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        widget_type   => 'text',
    }), "Lookup widget_type text" );
    is( scalar @fields, 2, "Check for 2 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        widget_type   => ANY('text', 'textarea'),
    }), "Lookup widget_type ANY('text', 'textarea')" );
    is( scalar @fields, 5, "Check for 5 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        widget_type   => 'text%',
    }), 'Lookup widget_type text%' );
    is( scalar @fields, 5, "Check for 5 fields" );

    # Try cols, rows, length.
    for my $attr (qw(cols rows length)) {
        ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
            element_type_id => $field{element_type_id},
            $attr           => 1
        }), "Lookup $attr 1" );
        is( scalar @fields, 1, "Check for 1 field" );
        ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
            element_type_id => $field{element_type_id},
            $attr           => ANY(1, 2, 4)
        }), "Lookup $attr ANY(1, 2, 4)" );
        is( scalar @fields, 3, "Check for 3 fields" );
    }

    # Try default_val.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        default_val   => 'foo1',
    }), "Lookup default_val foo" );
    is( scalar @fields, 1, "Check for 1 field" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        default_val   => ANY('foo1', 'foo3'),
    }), "Lookup default_val ANY('foo1', 'foo3')" );
    is( scalar @fields, 2, "Check for 2 fields" );
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        default_val   => 'foo%',
    }), 'Lookup default_val foo%' );
    is( scalar @fields, 5, "Check for 5 fields" );

    # Try active.
    ok( @fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        active     => 1
    }), "Lookup active 1" );
    is( scalar @fields, 5, "Check for 5 fields" );
    ok( !(@fields = Bric::Biz::AssetType::Parts::Data->list({
        element_type_id => $field{element_type_id},
        active     => 0
    })), "Lookup active 0" );
    is( scalar @fields, 0, "Check for 0 fields" );
}

##############################################################################
# Test the list_id() method.
sub test_list_ids : Test(90) {
    my $self = shift;

    ok my $elem = $self->element_type, "Get new element type object";
    $field{element_type_id} = $elem->get_id;

    # Create some test records.
    for my $n (1..5) {
        my %args = %field;
        # Make sure the name is unique.
        $args{key_name}     .= $n;
        $args{name}         .= $n;
        $args{description}  .= $n if $n % 2;
        $args{place}         = $n + 100;
        $args{quantifier}    = 0 if $n % 2;
        $args{required}      = 0 if $n % 2;
        $args{autopopulated} = 1 if $n % 2;
        $args{publishable}   = 0 unless $n % 2;
        $args{max_length}    = $n + 100;
        $args{sql_type}      = 'blob'     if $n % 2;
        $args{widget_type}   = 'textarea' if $n % 2;
        $args{cols}          = $n;
        $args{rows}          = $n;
        $args{length}        = $n;
        $args{default_val}   = "foo$n";
        ok( my $field = Bric::Biz::AssetType::Parts::Data->new(\%args),
            "Create $args{key_name}" );
        ok( $field->save, "Save $args{key_name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$field->get_id]);
    }

    # Try key_name + wildcard.
    ok( my @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        key_name => "$field{key_name}%"
    }), "Look up key_name $field{key_name}%" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );
    like $_, qr/^\d+$/, "Should be an ID" for @field_ids;

    # Try ANY key_name.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        key_name => ANY("$field{key_name}1", "$field{key_name}2"),
    }), qq{Look up key_name ANY("$field{key_name}1", "$field{key_name}2")} );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );

    # Try name.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        name => "$field{name}1"
    }), "Look up name $field{name}1" );
    is( scalar @field_ids, 1, "Check for 1 field ID" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        name => "$field{name}%"
    }), "Look up name $field{name}%" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        name => ANY("$field{name}1", "$field{name}2"),
    }), qq{Look up name ANY("$field{name}1", "$field{name}2")} );
    is( scalar @field_ids, 2, "Check for 2 field Ids" );

    # Try description.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        description => "$field{description}"
    }), "Look up description '$field{description}'" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );

    # Try ANY description.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        description => ANY("$field{description}", "$field{description}2"),
    }), qq{Look up description ANY("$field{description}", "$field{description}2")} );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );

    # Try element_type_id.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
    }), "Lookup element_type_id $field{element_type_id}," );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => ANY($field{element_type_id}, -101),
    }), "Lookup element_type_id ANY($field{element_type_id}, -101)" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );

    # Try place.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({ place => 101 }),
        "Lookup place 1" );
    is( scalar @field_ids, 1, "Check for 1 field ID" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        place => ANY(101, 102, 103)
    }), "Lookup place ANY(101, 102, 103)" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );

    # Try quantifier.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        quantifier => 1
    }), "Lookup quantifier 1" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        quantifier => 0
    }), "Lookup quantifier 0" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );

    # Try required.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        required   => 1
    }), "Lookup required 1" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        required   => 0
    }), "Lookup required 0" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );

    # Try autopopulated.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id    => $field{element_type_id},
        autopopulated => 1
    }), "Lookup autopopulated 1" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id    => $field{element_type_id},
        autopopulated => 0
    }), "Lookup autopopulated 0" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );

    # Try publishable.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id    => $field{element_type_id},
        publishable => 1
    }), "Lookup publishable 1" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id    => $field{element_type_id},
        publishable => 0
    }), "Lookup publishable 0" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );

    # Try max_length.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        max_length => 101,
    }), "Lookup max_length 1" );
    is( scalar @field_ids, 1, "Check for 1 field ID" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        max_length => ANY(101, 102, 103),
    }), "Lookup max_length ANY(101, 102, 103)" );
    is( scalar @field_ids, 3, "Check for 3 field IDs" );

    # Try sql_type.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        sql_type   => 'short',
    }), "Lookup sql_type short" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        sql_type   => ANY('short', 'blob'),
    }), "Lookup sql_type ANY('short', 'blob')" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );

    # Try widget_type.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        widget_type   => 'text',
    }), "Lookup widget_type text" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        widget_type   => ANY('text', 'textarea'),
    }), "Lookup widget_type ANY('text', 'textarea')" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        widget_type   => 'text%',
    }), 'Lookup widget_type text%' );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );

    # Try cols, rows, length.
    for my $attr (qw(cols rows length)) {
        ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
            element_type_id => $field{element_type_id},
            $attr           => 1
        }), "Lookup $attr 1" );
        is( scalar @field_ids, 1, "Check for 1 field ID" );
        ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
            element_type_id => $field{element_type_id},
            $attr           => ANY(1, 2, 4)
        }), "Lookup $attr ANY(1, 2, 4)" );
        is( scalar @field_ids, 3, "Check for 3 field IDs" );
    }

    # Try default_val.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        default_val   => 'foo1',
    }), "Lookup default_val foo" );
    is( scalar @field_ids, 1, "Check for 1 field ID" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        default_val   => ANY('foo1', 'foo3'),
    }), "Lookup default_val ANY('foo1', 'foo3')" );
    is( scalar @field_ids, 2, "Check for 2 field IDs" );
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        default_val   => 'foo%',
    }), 'Lookup default_val foo%' );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );

    # Try active.
    ok( @field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        active     => 1
    }), "Lookup active 1" );
    is( scalar @field_ids, 5, "Check for 5 field IDs" );
    ok( !(@field_ids = Bric::Biz::AssetType::Parts::Data->list_ids({
        element_type_id => $field{element_type_id},
        active     => 0
    })), "Lookup active 0" );
    is( scalar @field_ids, 0, "Check for 0 field IDs" );
}

##############################################################################
# Test the href() method.
sub href : Test(95) {
    my $self = shift;

    ok my $elem = $self->element_type, "Get new element type object";
    $field{element_type_id} = $elem->get_id;

    # Create some test records.
    for my $n (1..5) {
        my %args = %field;
        # Make sure the name is unique.
        $args{key_name}     .= $n;
        $args{name}         .= $n;
        $args{description}  .= $n if $n % 2;
        $args{place}         = $n + 100;
        $args{quantifier}    = 0 if $n % 2;
        $args{required}      = 0 if $n % 2;
        $args{autopopulated} = 1 if $n % 2;
        $args{publishable}   = 0 unless $n % 2;
        $args{max_length}    = $n + 100;
        $args{sql_type}      = 'blob'     if $n % 2;
        $args{widget_type}   = 'textarea' if $n % 2;
        $args{cols}          = $n;
        $args{rows}          = $n;
        $args{length}        = $n;
        $args{default_val}   = "foo$n";
        ok( my $field = Bric::Biz::AssetType::Parts::Data->new(\%args),
            "Create $args{key_name}" );
        ok( $field->save, "Save $args{key_name}" );
        # Save the ID for deleting.
        $self->add_del_ids([$field->get_id]);
    }

    # Try key_name + wildcard.
    ok( my $fields = Bric::Biz::AssetType::Parts::Data->href({
        key_name => "$field{key_name}%"
    }), "Look up key_name $field{key_name}%" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );
    isa_ok $_, 'Bric::Biz::AssetType::Parts::Data' for values %$fields;
    is $_, $fields->{$_}->get_id, "Should be indexed by ID" for keys %$fields;

    # Try ANY key_name.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        key_name => ANY("$field{key_name}1", "$field{key_name}2"),
    }), qq{Look up key_name ANY("$field{key_name}1", "$field{key_name}2")} );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try name.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        name => "$field{name}1"
    }), "Look up name $field{name}1" );
    is( scalar keys %$fields, 1, "Check for 1 field" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        name => "$field{name}%"
    }), "Look up name $field{name}%" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        name => ANY("$field{name}1", "$field{name}2"),
    }), qq{Look up name ANY("$field{name}1", "$field{name}2")} );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try description.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        description => "$field{description}"
    }), "Look up description '$field{description}'" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try ANY description.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        description => ANY("$field{description}", "$field{description}2"),
    }), qq{Look up description ANY("$field{description}", "$field{description}2")} );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try element_type_id.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
    }), "Lookup element_type_id $field{element_type_id}," );
    is( scalar keys %$fields, 5, "Check for 5 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => ANY($field{element_type_id}, -101),
    }), "Lookup element_type_id ANY($field{element_type_id}, -101)" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );

    # Try place.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({ place => 101 }),
        "Lookup place 1" );
    is( scalar keys %$fields, 1, "Check for 1 field" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        place => ANY(101, 102, 103)
    }), "Lookup place ANY(101, 102, 103)" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );

    # Try quantifier.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        quantifier => 1
    }), "Lookup quantifier 1" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        quantifier => 0
    }), "Lookup quantifier 0" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );

    # Try required.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        required   => 1
    }), "Lookup required 1" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        required   => 0
    }), "Lookup required 0" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );

    # Try autopopulated.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id    => $field{element_type_id},
        autopopulated => 1
    }), "Lookup autopopulated 1" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id    => $field{element_type_id},
        autopopulated => 0
    }), "Lookup autopopulated 0" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try publishable.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id    => $field{element_type_id},
        publishable => 1
    }), "Lookup publishable 1" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id    => $field{element_type_id},
        publishable => 0
    }), "Lookup publishable 0" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );

    # Try max_length.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        max_length => 101,
    }), "Lookup max_length 1" );
    is( scalar keys %$fields, 1, "Check for 1 field" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        max_length => ANY(101, 102, 103),
    }), "Lookup max_length ANY(101, 102, 103)" );
    is( scalar keys %$fields, 3, "Check for 3 fields" );

    # Try sql_type.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        sql_type   => 'short',
    }), "Lookup sql_type short" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        sql_type   => ANY('short', 'blob'),
    }), "Lookup sql_type ANY('short', 'blob')" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );

    # Try widget_type.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        widget_type   => 'text',
    }), "Lookup widget_type text" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        widget_type   => ANY('text', 'textarea'),
    }), "Lookup widget_type ANY('text', 'textarea')" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        widget_type   => 'text%',
    }), 'Lookup widget_type text%' );
    is( scalar keys %$fields, 5, "Check for 5 fields" );

    # Try cols, rows, length.
    for my $attr (qw(cols rows length)) {
        ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
            element_type_id => $field{element_type_id},
            $attr           => 1
        }), "Lookup $attr 1" );
        is( scalar keys %$fields, 1, "Check for 1 field" );
        ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
            element_type_id => $field{element_type_id},
            $attr           => ANY(1, 2, 4)
        }), "Lookup $attr ANY(1, 2, 4)" );
        is( scalar keys %$fields, 3, "Check for 3 fields" );
    }

    # Try default_val.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        default_val   => 'foo1',
    }), "Lookup default_val foo" );
    is( scalar keys %$fields, 1, "Check for 1 field" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        default_val   => ANY('foo1', 'foo3'),
    }), "Lookup default_val ANY('foo1', 'foo3')" );
    is( scalar keys %$fields, 2, "Check for 2 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        default_val   => 'foo%',
    }), 'Lookup default_val foo%' );
    is( scalar keys %$fields, 5, "Check for 5 fields" );

    # Try active.
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        active     => 1
    }), "Lookup active 1" );
    is( scalar keys %$fields, 5, "Check for 5 fields" );
    ok( $fields = Bric::Biz::AssetType::Parts::Data->href({
        element_type_id => $field{element_type_id},
        active     => 0
    }), "Lookup active 0" );
    is( scalar keys %$fields, 0, "Check for 0 fields" );
}

1;
__END__