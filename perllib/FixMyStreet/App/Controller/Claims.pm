package FixMyStreet::App::Controller::Claims;
use Moose;
use namespace::autoclean;

BEGIN { extends 'FixMyStreet::App::Controller::Form' }

use utf8;
use FixMyStreet::App::Form::Claims;

has feature => (
    is => 'ro',
    default => 'claims'
);

has form_class => (
    is => 'ro',
    default => 'FixMyStreet::App::Form::Claims',
);

has index_template => (
    is => 'ro',
    default => 'claims/index.html',
);

sub morm : Private {
    my ($self, $c) = @_;

    # Special button on map page to go back to address unknown (hard as form wraps whole page)
    if ($c->get_param('goto-address_unknown')) {
        $c->set_param('goto', 'address_unknown');
        $c->set_param('process', '');
    }

    my $form = $self->load_form($c);
    if ($c->get_param('process') && !$c->stash->{override_no_process}) {
        $c->forward('/auth/check_csrf_token');
        $form->process(params => $c->req->body_params);
        if ($form->validated) {
            $form = $self->load_form($c, $form);
        }
    }

    $form->process unless $form->processed;

    $c->stash->{template} = $form->template || 'claims/index.html';
    $c->stash->{form} = $form;
}

sub fields : Private {
    my ($self, $what, $fault_fixed) = @_;


    return [
        {
            stage => 'start',
            title => "About claim",
            fields => [
                {
                    desc => "What are you claiming for?",
                    value => 'what'
                },
                {
                    block => 'yes_no',
                    desc => "Claimed before",
                    value => 'claimed_before'
                }
            ]
        },
        {
            stage => 'about_you',
            title => "About you",
            fields => [
                {
                    desc => "Name",
                    value => 'name'
                },
                {
                    desc => "Email",
                    value => 'email'
                },
                {
                    desc => "Phone",
                    value => 'phone'
                },
                {
                    desc => "Address",
                    value => 'address'
                },
            ]
        },
        {
            stage => 'about_fault',
            title => "About the fault",
            fields => [
                {
                    desc => "Fixed",
                    block => "yes_no",
                    value => "fault_fixed",
                },
                {
                    desc => "Fault reported?",
                    hide => ($fault_fixed == 1),
                    value => 'fault_reported'
                },
                {
                    desc => "Fault ID",
                    hide => ($fault_fixed == 1),
                    value => 'report_id'
                },
            ]
        },
        {
            stage => 'when',
            title => "When did the incident happen?",
            fields => [
                {
                    desc => "Date",
                    value => 'incident_date'
                },
                {
                    desc => "Time",
                    value => 'incident_time'
                },
            ]
        },
        {
            stage => 'details',
            title => "What are the details of the incident",
            fields => [
                {
                    desc => "Weather",
                    value => 'weather'
                },
                {
                    desc => "Direction",
                    hide => ($what != 0),
                    value => 'direction'
                },
                {
                    desc => "Details",
                    value => 'details'
                },
                {
                    desc => "In Vehicle",
                    hide => ($what != 0),
                    block => 'yes_no',
                    value => 'in_vehicle'
                },
                {
                    desc => "Speed",
                    hide => ($what != 0),
                    value => 'speed'
                },
                {
                    desc => "Actions",
                    hide => ($what != 0),
                    value => 'actions'
                },
            ]
        },
        {
            stage => 'witnesses',
            title => "Witnesses and police",
            fields => [
                {
                    desc => "Were there any witnesses",
                    block => 'yes_no',
                    value => 'witnesses'
                },
                {
                    desc => "Witness details",
                    hide => 'witnesses != 1',
                    value => 'witness_details'
                },
                {
                    desc => "Did you report the incident to the police?",
                    block => 'yes_no',
                    value => 'report_police'
                },
                {
                    desc => "Incident Number",
                    hide => 'report_police != 1',
                    value => 'incident_number'
                },
            ]
        },
        {
            stage => 'cause',
            title => "What caused the incident",
            fields => [
                {
                    desc => "What was the cause of the incident",
                    value => 'what_cause'
                },
                {
                    desc => "Were you aware of it before",
                    block => 'yes_no',
                    value => 'aware'
                },
                {
                    desc => "Where was the cause of the incident?",
                    value => 'where_cause'
                },
                {
                    desc => "Describe the incident cause",
                    value => 'describe_cause'
                },
                {
                    desc => "Photos of incident",
                    value => 'photos'
                },
            ]
        },
        {
            stage => 'about_vehicle',
            hide => ($what != 0),
            title => "About the vehicle",
            fields => [
                {
                    desc => "Make",
                    value => 'make'
                },
                {
                    desc => "Registration",
                    value => 'registration'
                },
                {
                    desc => "Mileage",
                    value => 'mileage'
                },
                {
                    desc => "V5",
                    value => 'v5'
                },
                {
                    desc => "V5 in your name",
                    block => 'yes_no',
                    value => 'v5_in_name'
                },
                {
                    desc => "Insurer Address",
                    value => 'insurer_address'
                },
                {
                    desc => "Are you making a claim via insurer?",
                    block => 'yes_no',
                    value => 'damage_claim'
                },
                {
                    desc => "Are you registered for VAT?",
                    block => 'yes_no',
                    value => 'vat_reg'
                },
            ]
        },
        {
            stage => 'damage_vehicle',
            hide => ($what != 0),
            title => "What was the damage to the vehicle",
            fields => [
                {
                    desc => "Describe the damage to the vehicle",
                    value => 'vehicle_damage'
                },
                {
                    desc => "Please provide photos of the damage to the vehicle",
                    value => 'vehicle_photos'
                },
                {
                    desc => "Please provide receipted invoices for the repairs",
                    value => 'vehicle_receipts'
                },
                {
                    desc => "Are you claiming for tyre damage?",
                    block => 'yes_no',
                    value => 'tyre_damage'
                },
                {
                    desc => "Tyre mileage",
                    hide => 'tyre_damage != 1',
                    value => 'tyre_mileage'
                },
                {
                    desc => "Please provide copy of the tyre purchase receipts",
                    hide => 'tyre_damage != 1',
                    value => 'tyre_receipts'
                },
            ]
        },
        {
            stage => 'about_property',
            hide => ($what != 2),
            title => "About the property",
            fields => [
                {
                    desc => "Copy of insurance",
                    value => 'property_insurance'
                },
            ]
        },
        {
            stage => 'damage_property',
            hide => ($what != 2),
            title => "What was the damage to the property?",
            fields => [
                {
                    desc => "Describe the damage to the property",
                    value => 'property_damage_description'
                },
                {
                    desc => "Photos",
                    value => 'property_photos'
                },
                {
                    desc => "Invoices",
                    value => 'property_invoices'
                },
            ]
        },
        {
            stage => 'about_you_personal',
            title => "About you",
            hide => ($what != 1),
            fields => [
                {
                    desc => "Date of Birth",
                    value => 'dob'
                },
                {
                    desc => "National Insurance Number",
                    value => 'ni_number'
                },
                {
                    desc => "Occupation",
                    value => 'occupation'
                },
                {
                    desc => "Employer details",
                    value => 'employer_contact'
                },
            ]
        },
        {
            stage => 'injuries',
            hide => ($what != 1),
            title => "About your injuries",
            fields => [
                {
                    desc => "Descrit the injuries you sustained",
                    value => 'describe_injuries'
                },
                {
                    desc => "Did you seek medical attention",
                    block => 'yes_no',
                    value => 'medical_attention'
                },
                {
                    desc => "Date you received medical attention",
                    value => 'attention_date'
                },
                {
                    desc => "GP or hospital contact details",
                    value => 'gp_contact'
                },
                {
                    desc => "Absent from work",
                    block => 'yes_no',
                    value => 'absent_work'
                },
                {
                    desc => "Dates of absences",
                    value => 'absence_dates'
                },
                {
                    desc => "Are you having ongoing treatment?",
                    block => 'yes_no',
                    value => 'ongoing_treatment'
                },
                {
                    desc => "Treatment Details",
                    value => 'treatment_details'
                },
            ]
        },
    ]
}



sub process_claim : Private {
    my ($self, $c, $form) = @_;

    my $data = $form->saved_data;

    my $report_id = $data->{report_id};

    my $detail = "";

    for my $stage ( @{ $self->fields( $data->{what}, $data->{fault_fixed} ) } ) {
        next if $stage->{hide};
        for my $field ( @{ $stage->{fields} } ) {
            next if $field->{hide};
            $detail .= "$field->{desc}: " . $data->{$field->{value}} . "\n";
        }
    }

    my $user = $c->user_exists
        ? $c->user->obj
        : $c->model('DB::User')->find_or_new( { email => $data->{email} } );
    $user->name($data->{name}) if $data->{name};
    $user->phone($data->{phone}) if $data->{phone};

    my $report;
    if ( $report_id ) {
        $report = FixMyStreet::DB->resultset('Problem')->find($report_id);
    } else {
        $report = $c->model('DB::Problem')->new({
            non_public => 1,
            state => 'unconfirmed',
            cobrand => $c->cobrand->moniker,
            cobrand_data => 'noise',
            lang => $c->stash->{lang_code},
            user => $user, # XXX
            name => $data->{name},
            anonymous => 0,
            extra => $data,
            category => 'Claim',
            used_map => 1,
            title => 'Claim',
            detail => $detail,
            postcode => '',
            latitude => $data->{latitude},
            longitude => $data->{longitude},
            areas => '',
            send_questionnaire => 0,
            bodies_str => $c->cobrand->body->id,
        });
    }

    $c->stash->{detail} = $detail;

}

__PACKAGE__->meta->make_immutable;

1;
