package Bric::Biz::AssetType;

# $Id $
###############################################################################

=head1 NAME

Bric::Biz::AssetType - Deprecated; use Bric::Biz::ElementType instead

=cut

require Bric; our $VERSION = Bric->VERSION;

=head1 DESCRIPTION

The functionality of this class has been moved to
L<Bric::Biz::ElementType|Bric::Biz::ElementType>. Please use that class,
instead.

=cut

use base 'Bric::Biz::ElementType';
use Bric::Biz::AssetType::Parts::Data;

1;
__END__
