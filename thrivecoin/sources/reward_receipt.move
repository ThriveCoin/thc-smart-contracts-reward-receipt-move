module thrivecoin::reward_receipt {
  // imports
  use sui::object::{Self, ID, UID};
  use sui::transfer;
  use sui::tx_context::{Self, TxContext};
  use sui::event;
  use sui::vec_set::{Self, VecSet};
  use std::string::{Self, String};
  use sui::package;
  use sui::display;

  // errors
  const ENotWriter: u64 = 1;

  // structures
  struct AdminRole has key {
    id: UID
  }

  struct WriterRole has key {
    id: UID,
    list: VecSet<address>
  }

  struct RewardReceipt has key, store {
    id: UID,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String
  }

  struct RewardReceiptStored has copy, drop {
    reward_receipt_id: ID,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String
  }

  // OTW
  struct REWARD_RECEIPT has drop {}

  // initializer
  fun init(otw: REWARD_RECEIPT, ctx: &mut TxContext) {
    let publisher = package::claim(otw, ctx);

    let display_keys = vector[
      string::utf8(b"id"),
      string::utf8(b"recipient"),
      string::utf8(b"transfer_tx"),
      string::utf8(b"version"),
      string::utf8(b"timestamp"),
      string::utf8(b"meta_data_uri"),
    ];

    let display_values = vector[
      string::utf8(b"{id}"),
      string::utf8(b"{recipient}"),
      string::utf8(b"{transfer_tx}"),
      string::utf8(b"{version}"),
      string::utf8(b"{timestamp}"),
      string::utf8(b"{meta_data_uri}"),
    ];

    let display = display::new_with_fields<RewardReceipt>(
      &publisher, display_keys, display_values, ctx
    );
    display::update_version(&mut display);

    transfer::public_transfer(publisher, tx_context::sender(ctx));
    transfer::public_transfer(display, tx_context::sender(ctx));

    transfer::transfer(AdminRole {
      id: object::new(ctx)
    }, tx_context::sender(ctx));

    transfer::share_object(WriterRole {
      id: object::new(ctx),
      list: vec_set::singleton(tx_context::sender(ctx))
    });
  }

  // role functions
  public fun transfer_admin_role (admin_role: AdminRole, new_owner: address) {
    transfer::transfer(admin_role, new_owner);
  }

  public fun add_writer (_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::insert(&mut writer_role.list, account);
  }

  public fun del_writer(_: &AdminRole, writer_role: &mut WriterRole, account: address) {
    vec_set::remove(&mut writer_role.list, &account);
  }

  // receipt functions
  public fun add_receipt (
    writer_role: &WriterRole,
    recipient: address,
    transfer_tx: String,
    version: String,
    timestamp: u64,
    meta_data_uri: String,
    ctx: &mut TxContext
  ) {
    assert!(vec_set::contains(&writer_role.list, &tx_context::sender(ctx)), ENotWriter);

    let receipt = RewardReceipt {
      id: object::new(ctx),
      recipient,
      transfer_tx,
      version,
      timestamp,
      meta_data_uri
    };

    event::emit(RewardReceiptStored {
      reward_receipt_id: object::uid_to_inner(&receipt.id),
      recipient,
      transfer_tx,
      version,
      timestamp,
      meta_data_uri
    });

    transfer::public_freeze_object(receipt);
  }

  public fun recipient(self: &RewardReceipt): address { self.recipient }

  public fun transfer_tx(self: &RewardReceipt): String { self.transfer_tx }

  public fun version(self: &RewardReceipt): String { self.version }

  public fun timestamp(self: &RewardReceipt): u64 { self.timestamp }

  public fun meta_data_uri(self: &RewardReceipt): String { self.meta_data_uri }

  // unit tests
  #[test_only] use sui::test_scenario as ts;

  #[test_only] use std::vector;

  #[test_only] const ADMIN: address = @0xAD;

  #[test]
  fun test_module_init () {
    let ts = ts::begin(@0x0);
    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::size(&writer.list) == 1, 1);
      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_transfer_admin_role () {
    let ts = ts::begin(@0x0);
    let new_owner: address = @0xAD2;

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    // ensure that admin role belongs to ADMIN
    {
      ts::next_tx(&mut ts, ADMIN);
      let role: AdminRole = ts::take_from_sender(&ts);
      transfer_admin_role(role, new_owner);
    };

    {
      ts::next_tx(&mut ts, ADMIN);

      let ids_admin = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids_admin) == 0, 1);

      let ids_new_owner = ts::ids_for_address<AdminRole>(new_owner);
      assert!(vector::length(&ids_new_owner) == 1, 1);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::contains(&writer.list, &writer_acc), 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_del_writer () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::contains(&writer.list, &writer_acc), 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      del_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::contains(&writer.list, &writer_acc) == false, 1);

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  #[expected_failure(abort_code = ENotWriter)]
  fun test_add_receipt_role_fail () {
    let ts = ts::begin(@0x0);
    let non_writer = @0xAD2;

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let ids = ts::ids_for_address<AdminRole>(ADMIN);
      assert!(vector::length(&ids) == 1, 1);

      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::size(&writer.list) == 1, 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, non_writer);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    ts::end(ts);
  }

  #[test]
  fun test_add_receipt_role_success () {
    let ts = ts::begin(@0x0);
    let writer_acc: address = @0xAD2;

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let admin: AdminRole = ts::take_from_sender(&ts);
      let writer: WriterRole = ts::take_shared(&ts);

      add_writer(&admin, &mut writer, writer_acc);

      ts::return_to_sender(&ts, admin);
      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);

      let admin_ref = ADMIN;
      assert!(vec_set::contains(&writer.list, &admin_ref), 1);
      assert!(vec_set::contains(&writer.list, &writer_acc), 1);

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, writer_acc);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let receipt: RewardReceipt = ts::take_immutable(&ts);

      assert!(receipt.recipient == @0xB1, 1);
      assert!(receipt.transfer_tx == string::utf8(b"test receipt"), 1);
      assert!(receipt.version == string::utf8(b"v1"), 1);
      assert!(receipt.timestamp == 1706630649541, 1);
      assert!(receipt.meta_data_uri == string::utf8(b"http://example.com/123"), 1);

      ts::return_immutable(receipt);
    };

    ts::end(ts);
  }

  #[test]
  fun test_receipt_view_methods () {
    let ts = ts::begin(@0x0);

    {
      let otw = REWARD_RECEIPT {};
      ts::next_tx(&mut ts, ADMIN);
      init(otw, ts::ctx(&mut ts));
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let writer: WriterRole = ts::take_shared(&ts);
      let ctx = ts::ctx(&mut ts);

      add_receipt(
        &writer, 
        @0xB1,
        string::utf8(b"test receipt"),
        string::utf8(b"v1"),
        1706630649541,
        string::utf8(b"http://example.com/123"),
        ctx
      );

      ts::return_shared(writer);
    };

    {
      ts::next_tx(&mut ts, ADMIN);
      let receipt: RewardReceipt = ts::take_immutable(&ts);

      assert!(recipient(&receipt) == @0xB1, 1);
      assert!(transfer_tx(&receipt) == string::utf8(b"test receipt"), 1);
      assert!(version(&receipt) == string::utf8(b"v1"), 1);
      assert!(timestamp(&receipt) == 1706630649541, 1);
      assert!(meta_data_uri(&receipt) == string::utf8(b"http://example.com/123"), 1);

      ts::return_immutable(receipt);
    };

    ts::end(ts);
  }
}
