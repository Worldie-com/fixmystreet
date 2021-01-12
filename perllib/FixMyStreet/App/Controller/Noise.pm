package FixMyStreet::App::Controller::Noise;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

use FixMyStreet::App::Form::Noise;

sub auto : Private {
    my ( $self, $c ) = @_;
    my $cobrand_check = $c->cobrand->feature('noise');
    $c->detach( '/page_error_404_not_found' ) if !$cobrand_check;
    return 1;
}

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('/auth/get_csrf_token');
    $c->forward('form');
}

# For if we were redirected to login
sub existing : Local : Args(0) {
    my ($self, $c) = @_;

    $c->forward('/auth/get_csrf_token');
    $c->set_param('token', $c->stash->{csrf_token});
    $c->set_param('process', 'existing_issue');
    $c->set_param('existing', 1);
    $c->forward('form');
}

sub load_form {
    my ($c, $previous_form) = @_;

    my $page;
    if ($previous_form) {
        $page = $previous_form->next;
    } else {
        $page = $c->forward('get_page');
    }

    my $form = FixMyStreet::App::Form::Noise->new(
        page_name => $page,
        csrf_token => $c->stash->{csrf_token},
        c => $c,
        previous_form => $previous_form,
        saved_data_encoded => $c->get_param('saved_data'),
        no_preload => 1,
    );

    if (!$form->has_current_page) {
        $c->detach('/page_error_400_bad_request', [ 'Bad request' ]);
    }

    if ($form->requires_sign_in && !$c->user_exists) {
        $c->res->redirect('/auth?r=noise/existing');
        $c->detach;
    }

    return $form;
}

sub form : Private {
    my ($self, $c) = @_;

    # Special button on map page to go back to address unknown (hard as form wraps whole page)
    if ($c->get_param('goto-address_unknown')) {
        $c->set_param('goto', 'address_unknown');
        $c->set_param('process', '');
    }

    my $form = load_form($c);
    if ($c->get_param('process') && !$c->stash->{override_no_process}) {
        $c->forward('/auth/check_csrf_token');
        $form->process(params => $c->req->body_params);
        if ($form->validated) {
            $form = load_form($c, $form);
        }
    }

    $form->process unless $form->processed;

    $c->stash->{template} = $form->template || 'noise/index.html';
    $c->stash->{form} = $form;
}

sub get_page : Private {
    my ($self, $c) = @_;

    my $goto = $c->get_param('goto') || '';
    my $process = $c->get_param('process') || '';
    $goto = 'intro' unless $goto || $process;
    if ($goto && $process) {
        $c->detach('/page_error_400_bad_request', [ 'Bad request' ]);
    }

    return $goto || $process;
}

sub process_noise_report : Private {
    my ($self, $c, $form) = @_;

    my $data = $form->saved_data;

    # Is this the best way to do it?
    my $contributing_as_another_user = $c->user_exists && $c->user->from_body && $data->{email} && $c->user->email ne $data->{email};

    my $user = $c->user_exists && !$contributing_as_another_user
        ? $c->user->obj
        : $c->model('DB::User')->find_or_new( { email => $data->{email} } );
    $user->name($data->{name}) if $data->{name};
    $user->phone($data->{phone}) if $data->{phone};

    my %shared = (
        state => 'unconfirmed',
        cobrand => $c->cobrand->moniker,
        cobrand_data => 'noise',
        lang => $c->stash->{lang_code},
        user => $user,
        name => $user->name,
        anonymous => 0,
        extra => $data,
    );
    my $object;
    my $now = $data->{happening_now} ? 'Yes' : 'No';
    my $days = join(', ', @{$data->{happening_days}||[]});
    my $times = join(', ', @{$data->{happening_time}||[]});
    my $time_detail;
    if ($data->{happening_pattern}) {
        $time_detail = "Does the time of the noise follow a pattern? Yes
What days does the noise happen? $days
What time does the noise happen? $times";
    } else {
        $time_detail = "Does the time of the noise follow a pattern? No
When has the noise occurred? $data->{happening_description}";
    }
    if ($data->{report}) {
        # Update on existing report. Will be logged in.
        my $report = FixMyStreet::DB->resultset('Problem')->find($data->{report});

        # Create an update!
        my $text = <<EOF;
Kind of noise: $data->{kind}
Noise details: $data->{more_details}

Is the noise happening now? $now
$time_detail
EOF
        $object = $c->model('DB::Comment')->new({
            problem => $report,
            text => $text,
            problem_state => $report->state,
            %shared,
        });
    } else {
        # New report
        my $title = 'Noise report';

        my $addr = $data->{source_address} ? $data->{source_address} : "$data->{latitude}, $data->{longitude}, $data->{radius}";
        my $detail = <<EOF;
Kind of noise: $data->{kind}
Noise details: $data->{more_details}

Where is the noise coming from? $data->{where}
Noise source: $addr

Is the noise happening now? $now
$time_detail
EOF
        $object = $c->model('DB::Problem')->new({
            non_public => 1,
            category => 'Noise report',
            used_map => 1,
            title => $title,
            detail => $detail,
            postcode => '',
            latitude => $data->{latitude},
            longitude => $data->{longitude},
            areas => '',
            send_questionnaire => 0,
            bodies_str => $c->cobrand->body->id,
            %shared,
        });

        $c->stash->{report} = $object;
    }

    if ($contributing_as_another_user) {
        $object->set_extra_metadata( contributed_as => 'another_user');
        $object->set_extra_metadata( contributed_by => $c->user->id );
    } elsif ( !$object->user->in_storage ) {
        $object->user->insert();
    } elsif ( $c->user && $object->user->id == $c->user->id ) {
        $object->user->update();
    } else {
        $object->user->discard_changes();
    }

    $object->confirm;
    $object->insert;

    if ($c->stash->{report}) {
        $c->forward('/report/new/create_related_things');
    }

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
