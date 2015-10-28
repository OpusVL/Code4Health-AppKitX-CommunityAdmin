package Code4Health::AppKitX::CommunityAdmin::Controller::CommunityAdmin;

use Moose;
use namespace::autoclean;
use Text::CSV;
BEGIN { extends 'Catalyst::Controller::HTML::FormFu'; };
with 'OpusVL::AppKit::RolesFor::Controller::GUI';

__PACKAGE__->config
(
    appkit_name                 => 'Communities',
    appkit_myclass              => 'Code4Health::AppKitX::CommunityAdmin',
    appkit_method_group         => 'Communities',
    appkit_shared_module        => 'Communities',
);

sub auto : Action {
    my ($self, $c) = @_;
    my $index_url = $c->uri_for($self->action_for('list'));
    $c->stash->{index_url} = $index_url;
    $self->add_breadcrumb($c, { name => 'Communities', url => $index_url });
}

sub list
    : Local
    : Args(0)
    : NavigationName('List Communities')
    : AppKitFeature('Communities')
{
    my ($self, $c) = @_;

    my $communities = [$c->model('Users::Community')->active->by_name];

    $c->stash->{communities} = $communities;
    $c->stash->{add_url} = $c->uri_for($self->action_for('add'));
    $c->stash->{url} = sub
    {
        my $action_name = shift;
        my $community = shift;
        my $action = $self->action_for($action_name);
        return $c->uri_for($action, [ $community->code ]);
    };
}

sub add
    : Local
    : AppKitFeature('Communities')
    : AppKitForm
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Add');
    if($c->req->param('cancel'))
    {
        $c->res->redirect($c->stash->{index_url});
        $c->detach;
    }
    my $form = $c->stash->{form};
    if($form->submitted_and_valid)
    {
        my $data = {
            name => $form->param_value('name'),
            code => $form->param_value('code'),
        };
        $c->model('Users::Community')->create($data);
        $c->flash->{status_msg} = 'Added community';
        $c->res->redirect($c->stash->{index_url});
    }
}

sub community_chain
    : Chained('/')
    : CaptureArgs(1)
    : PathPart('community')
    : AppKitFeature('Communities')
{
    my ($self, $c, $code) = @_;

    my $community = $c->model('Users::Community')->find({ code => $code, status => 'active' });
    $c->detach('/not_found') unless $community;
    $c->stash->{community} = $community;
    my $url = $c->uri_for($self->action_for('edit'), [$community->code]);
    $c->stash->{url} = $url;
    $self->add_breadcrumb($c, { name => $community->name, url => $url });
}

sub edit
    : Chained('community_chain')
    : AppKitFeature('Communities')
    : AppKitForm('communityadmin/add.yml')
    : PathPart('edit')
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Edit');
    if($c->req->param('cancel'))
    {
        $c->res->redirect($c->stash->{index_url});
        $c->detach;
    }
    my $form = $c->stash->{form};
    my $community = $c->stash->{community};
    if($form->submitted_and_valid)
    {
        my $data = {
            name => $form->param_value('name'),
            code => $form->param_value('code'),
        };
        $community->update($data);
        $c->flash->{status_msg} = 'Changes saved';
        $c->res->redirect($c->stash->{index_url});
    }
    else
    {
        $form->default_values({
            name => $community->name,
            code => $community->code,
        });
    }
}

sub delete
    : Chained('community_chain')
    : AppKitFeature('Communities')
    : AppKitForm
    : PathPart('delete')
{
    my ($self, $c) = @_;

    $self->add_final_crumb($c, 'Delete');
    if($c->req->param('cancel'))
    {
        $c->res->redirect($c->stash->{index_url});
        $c->detach;
    }
    my $form = $c->stash->{form};
    my $community = $c->stash->{community};
    if($form->submitted_and_valid)
    {
        $community->delete;
        $c->flash->{status_msg} = 'Changes saved';
        $c->res->redirect($c->stash->{index_url});
    }
}

sub member_list
    : Chained('community_chain')
    : AppKitFeature('Communities')
    : PathPart('members')
{
    my ($self, $c) = @_;

    # produce a csv of the members.
    my $community = $c->stash->{community};
    my $people = $community->people;
    my @people = $people->search(undef, {
        order_by => ['surname', 'first_name'],
        columns => [qw/first_name surname email_address/]
    })->all;
    my @data = map { [ $_->first_name, $_->surname, $_->email_address ] } @people;
    my $csv = Text::CSV->new ( { binary => 1 } )
        or die "Cannot use CSV: ".Text::CSV->error_diag ();
    my $data = '';
    open my $fh, '>', \$data;
    $csv->print ($fh, $_) for @data;
    close $fh;


    my $content_type = 'text/csv';
    my $safe_code = $community->code =~ s/[^\w_-]/-/gr;
    my $filename = $safe_code . '-members.csv';

    $c->forward( $c->view('DownloadFile'), [ { content_type => $content_type, body => $data, header => $filename } ] );
}

1;
