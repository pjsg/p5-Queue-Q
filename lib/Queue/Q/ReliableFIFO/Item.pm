package Queue::Q::ReliableFIFO::Item;
use strict;

# for reasons of debugging, JSON is easier, while Serial::* is 
# faster (about 7%) and delivers smaller serialized blobs.
use JSON::XS; # use the real stuff, no fall back on pure Perl JSON please
my $serializer   = JSON::XS->new->pretty(0);
my $deserializer = JSON::XS->new->pretty(0);

#use Sereal::Encoder;
#use Sereal::Decoder;
#my $serializer   = Sereal::Encoder->new();
#my $deserializer = Sereal::Decoder->new();
use Data::Dumper;

sub new {
    my $class = shift;
    my $self = bless { @_ }, $class;

    if (!exists $self->{_serialized}) {
        $self->{_serialized} ||=
            $serializer->encode({
                t => time(),
                b => $self->{data}
             });
    }
    return $self;
}
sub time        { shift->_get('time'); }
sub data        { shift->_get('data'); }
sub nr_requeues { shift->_get('nr_requeues') || 0; }
sub _get { 
    my ($self, $elem) = @_;
    $self->_deserialize if ! exists $self->{data};
    return exists $self->{$elem} ? $self->{$elem} : undef;
}
sub _serialized { $_[0]->{_serialized}; }
sub inc_nr_requeues {
    my $self = shift;
    my $plain = $deserializer->decode($self->{_serialized});
    $self->{nr_requeues} = ++$plain->{nr};
    $self->{_serialized} =  $serializer->encode($plain);
    #print $self->{_serialized}, "\n";
    return $self->{nr_requeues};
}
sub _deserialize {
    my $self = shift;
    my $plain = $deserializer->decode($self->{_serialized});
    $self->{time} = $plain->{t};
    $self->{nr_requeues} = $plain->{nr} if exists $plain->{nr};
    $self->{data} = $plain->{b};
}
1;