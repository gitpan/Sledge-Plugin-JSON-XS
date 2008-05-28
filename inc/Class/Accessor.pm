#line 1
package Class::Accessor;
require 5.00502;
use strict;
$Class::Accessor::VERSION = '0.31';

#line 113

sub new {
    my($proto, $fields) = @_;
    my($class) = ref $proto || $proto;

    $fields = {} unless defined $fields;

    # make a copy of $fields.
    bless {%$fields}, $class;
}

#line 140

sub mk_accessors {
    my($self, @fields) = @_;

    $self->_mk_accessors('rw', @fields);
}


{
    no strict 'refs';

    sub _mk_accessors {
        my($self, $access, @fields) = @_;
        my $class = ref $self || $self;
        my $ra = $access eq 'rw' || $access eq 'ro';
        my $wa = $access eq 'rw' || $access eq 'wo';

        foreach my $field (@fields) {
            my $accessor_name = $self->accessor_name_for($field);
            my $mutator_name = $self->mutator_name_for($field);
            if( $accessor_name eq 'DESTROY' or $mutator_name eq 'DESTROY' ) {
                $self->_carp("Having a data accessor named DESTROY  in '$class' is unwise.");
            }
            if ($accessor_name eq $mutator_name) {
                my $accessor;
                if ($ra && $wa) {
                    $accessor = $self->make_accessor($field);
                } elsif ($ra) {
                    $accessor = $self->make_ro_accessor($field);
                } else {
                    $accessor = $self->make_wo_accessor($field);
                }
                unless (defined &{"${class}::$accessor_name"}) {
                    *{"${class}::$accessor_name"} = $accessor;
                }
                if ($accessor_name eq $field) {
                    # the old behaviour
                    my $alias = "_${field}_accessor";
                    *{"${class}::$alias"} = $accessor unless defined &{"${class}::$alias"};
                }
            } else {
                if ($ra and not defined &{"${class}::$accessor_name"}) {
                    *{"${class}::$accessor_name"} = $self->make_ro_accessor($field);
                }
                if ($wa and not defined &{"${class}::$mutator_name"}) {
                    *{"${class}::$mutator_name"} = $self->make_wo_accessor($field);
                }
            }
        }
    }

    sub follow_best_practice {
        my($self) = @_;
        my $class = ref $self || $self;
        *{"${class}::accessor_name_for"}  = \&best_practice_accessor_name_for;
        *{"${class}::mutator_name_for"}  = \&best_practice_mutator_name_for;
    }

}

#line 219

sub mk_ro_accessors {
    my($self, @fields) = @_;

    $self->_mk_accessors('ro', @fields);
}

#line 247

sub mk_wo_accessors {
    my($self, @fields) = @_;

    $self->_mk_accessors('wo', @fields);
}

#line 290

sub best_practice_accessor_name_for {
    my ($class, $field) = @_;
    return "get_$field";
}

sub best_practice_mutator_name_for {
    my ($class, $field) = @_;
    return "set_$field";
}

sub accessor_name_for {
    my ($class, $field) = @_;
    return $field;
}

sub mutator_name_for {
    my ($class, $field) = @_;
    return $field;
}

#line 329

sub set {
    my($self, $key) = splice(@_, 0, 2);

    if(@_ == 1) {
        $self->{$key} = $_[0];
    }
    elsif(@_ > 1) {
        $self->{$key} = [@_];
    }
    else {
        $self->_croak("Wrong number of arguments received");
    }
}

#line 354

sub get {
    my $self = shift;

    if(@_ == 1) {
        return $self->{$_[0]};
    }
    elsif( @_ > 1 ) {
        return @{$self}{@_};
    }
    else {
        $self->_croak("Wrong number of arguments received");
    }
}

#line 380

sub make_accessor {
    my ($class, $field) = @_;

    # Build a closure around $field.
    return sub {
        my $self = shift;

        if(@_) {
            return $self->set($field, @_);
        }
        else {
            return $self->get($field);
        }
    };
}

#line 407

sub make_ro_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        if (@_) {
            my $caller = caller;
            $self->_croak("'$caller' cannot alter the value of '$field' on objects of class '$class'");
        }
        else {
            return $self->get($field);
        }
    };
}

#line 434

sub make_wo_accessor {
    my($class, $field) = @_;

    return sub {
        my $self = shift;

        unless (@_) {
            my $caller = caller;
            $self->_croak("'$caller' cannot access the value of '$field' on objects of class '$class'");
        }
        else {
            return $self->set($field, @_);
        }
    };
}

#line 458

use Carp ();

sub _carp {
    my ($self, $msg) = @_;
    Carp::carp($msg || $self);
    return;
}

sub _croak {
    my ($self, $msg) = @_;
    Carp::croak($msg || $self);
    return;
}

#line 673

1;
